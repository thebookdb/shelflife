class LibraryItem < ApplicationRecord
  belongs_to :product, foreign_key: :product_id
  belongs_to :library, foreign_key: :library_id
  belongs_to :condition, optional: true
  belongs_to :item_status, optional: true
  belongs_to :acquisition_source, optional: true
  belongs_to :ownership_status, optional: true
  belongs_to :added_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  serialize :tags, type: Array, coder: JSON

  validates :product_id, presence: true
  validates :library_id, presence: true
  validates :acquisition_price, :replacement_cost, :original_retail_price, :current_market_value,
    numericality: {greater_than_or_equal_to: 0}, allow_nil: true

  # Scopes
  attribute :intent, :integer, default: 0
  enum :intent, {have: 0, want: 1}

  scope :recent, -> { order(date_added: :desc) }
  scope :in_library, ->(library) { where(library: library) }
  scope :favorites, -> { where(is_favorite: true) }
  scope :by_condition, ->(condition) { where(condition: condition) }
  scope :with_condition, ->(condition_name) { joins(:condition).where(conditions: {name: condition_name}) }
  scope :with_status, ->(status_name) { joins(:item_status).where(item_statuses: {name: status_name}) }

  before_create :set_date_added
  before_save :update_last_accessed
  before_destroy :prevent_orphaning_product

  def update_condition(new_condition, notes = nil)
    condition_record = new_condition.is_a?(Condition) ? new_condition : Condition.find_by(name: new_condition)
    return false unless condition_record

    update(
      condition: condition_record,
      condition_notes: notes,
      last_condition_check: Date.current
    )
  end

  def days_owned
    return nil unless acquisition_date
    (Date.current - acquisition_date).to_i
  end

  def estimated_value
    current_market_value.presence || replacement_cost.presence || original_retail_price
  end

  def condition_status
    condition&.name || "Unknown"
  end

  private

  def set_date_added
    self.date_added ||= Time.current
  end

  def update_last_accessed
    self.last_accessed = Time.current if changed? && !new_record?
  end

  def prevent_orphaning_product
    return if product.library_items.count > 1

    errors.add(:base, "Cannot remove the last library for a product")
    throw(:abort)
  end
end
