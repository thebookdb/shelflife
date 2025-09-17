class Product < ApplicationRecord
  has_many :library_items, foreign_key: :product_id, dependent: :destroy
  has_many :libraries, through: :library_items
  has_many :scans, foreign_key: :product_id, dependent: :destroy

  has_one_attached :cover_image

  validates :gtin, presence: true, uniqueness: true, format: { with: /\A\d{13}\z/, message: "must be 13 digits" }
  # validates :title, presence: true, on: :update
  validates :product_type, presence: true

  after_create :enrich_from_tbdb!
  after_update :broadcast_scan_updates, if: :saved_change_to_tbdb_data?
  before_save :validate_barcode

  enum :product_type, {
    book: 1,
    video: 2,
    ebook: 3,
    audiobook: 4,
    toy: 5,
    lego: 6,
    pop: 7,
    graphic_novel: 8,
    box_set: 9,
    music: 10,
    ereader: 11,
    table_top_game: 12,
    other: 99
  }

  # Scopes for filtering
  scope :valid_barcodes, -> { where(valid_barcode: true) }
  scope :invalid_barcodes, -> { where(valid_barcode: false) }

  # Find or create by GTIN with basic product info
  def self.find_or_create_by_gtin(gtin, basic_info = {})
    # Validate GTIN format
    unless gtin&.match?(/\A\d{13}\z/)
      raise ArgumentError, "Invalid GTIN format: #{gtin}"
    end

    find_or_create_by(gtin: gtin) do |product|
      product.title = basic_info[:title]
      product.author = basic_info[:author]
      product.publisher = basic_info[:publisher]
      product.product_type = basic_info[:product_type] || "book"
    end
  end

  def self.findd(...) = find_or_create_by_gtin(...)

  # Check if product data has been successfully enriched from TBDB
  def enriched?
    tbdb_data.present? && tbdb_data["status"] == "success"
  end

  # Check if product has a failed enrichment attempt
  def enrichment_failed?
    tbdb_data.present? && tbdb_data["status"] == "error"
  end

  # Allow re-attempting failed enrichments
  def retry_enrichment!
    if enrichment_failed?
      update!(tbdb_data: nil)
      enrich_from_tbdb!
    end
  end

  # Queue job to fetch data from TBDB
  def enrich_from_tbdb!
    return if enriched?

    Rails.logger.info("Enqueueing ProductDataFetchJob for product #{gtin}")
    job = ProductDataFetchJob.perform_later(self)
    Rails.logger.info("Enqueued ProductDataFetchJob with job_id: #{job.job_id} for product #{gtin}")
    job
  end

  def enrich!
    update(tbdb_data: {})
    ProductEnrichmentService.new.call(self)
  end

  # Library helpers
  def in_library?(library)
    library_items.where(library: library).exists?
  end

  def copies_in_library(library)
    library_items.where(library: library).count
  end

  # Safe title that falls back to GTIN if title is not set
  def safe_title
    title.presence || "Product #{gtin}"
  end

  def self.bookland?(gtin) = gtin.starts_with?("978") || gtin.starts_with?("979")

  private

  # Broadcast updates to all scans when product data changes
  def broadcast_scan_updates
    # Broadcast to product show page for real-time updates
    Turbo::StreamsChannel.broadcast_replace_to(
      "product_#{id}",
      target: "product-data",
      renderable: Components::Products::DisplayDataView.new(product: self, libraries: [])
    )

    # Broadcast to scans page
    scans.includes(:product).find_each do |scan|
      scan.broadcast_replace_to(
        "scans",
        target: ActionView::RecordIdentifier.dom_id(scan),
        renderable: Components::Scans::ScanItemView.new(scan: scan)
      )
    end
  end

  # Validate and set the valid_barcode flag
  def validate_barcode
    self.valid_barcode = BarcodeValidationService.valid_barcode?(gtin) if gtin.present?
  end
end
