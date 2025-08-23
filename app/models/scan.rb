class Scan < ApplicationRecord
  belongs_to :product, foreign_key: :product_id
  belongs_to :user, foreign_key: :user_id

  validates :product_id, presence: true
  validates :user_id, presence: true
  validates :scanned_at, presence: true

  scope :recent, -> { order(scanned_at: :desc) }
  scope :last_n, ->(n) { recent.limit(n) }

  # Track a product scan
  def self.track_scan(product, user: Current.user)
    # Remove any existing scans for this product to avoid duplicates
    return if Scan.last&.product == product

    existing_scans = where(product: product)
    existing_scans.each do |scan|
      scan.broadcast_remove_to("scans", target: ActionView::RecordIdentifier.dom_id(scan))
    end
    existing_scans.delete_all

    # Create the new scan record with user association
    new_scan = create!(product: product, user: user, scanned_at: Time.current)
    new_scan.broadcast_prepend_to(
      "scans",
      target: "recent_scans",
      renderable: Components::Scans::ScanItemView.new(scan: new_scan)
    )

    new_scan
  end
end
