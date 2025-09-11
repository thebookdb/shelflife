class LibraryItem < ApplicationRecord
  belongs_to :product, foreign_key: :product_id
  belongs_to :library, foreign_key: :library_id

  validates :product_id, presence: true
  validates :library_id, presence: true
  validates :acquisition_price, :replacement_cost, :original_retail_price, :current_market_value,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Enums for status tracking
  enum :status, {
    available: "available",
    checked_out: "checked_out", 
    missing: "missing",
    damaged: "damaged",
    in_repair: "in_repair",
    retired: "retired"
  }, default: :available

  enum :ownership_status, {
    owned: "owned",
    borrowed: "borrowed",
    on_loan: "on_loan",
    consignment: "consignment"
  }, default: :owned

  enum :acquisition_source, {
    purchased: "purchased",
    gift: "gift",
    borrowed: "borrowed",
    found: "found",
    inherited: "inherited",
    trade: "trade",
    review_copy: "review_copy"
  }

  # Scopes
  scope :recent, -> { order(date_added: :desc) }
  scope :in_library, ->(library) { where(library: library) }
  scope :wishlist_items, -> { joins(:library).where(libraries: { name: "Wishlist" }) }
  scope :owned_items, -> { joins(:library).where.not(libraries: { name: "Wishlist" }) }
  scope :favorites, -> { where(is_favorite: true) }
  scope :by_condition, ->(condition) { where(condition: condition) }
  scope :overdue, -> { where("due_date < ?", Date.current) }
  scope :checked_out, -> { where(status: :checked_out) }
  scope :available, -> { where(status: :available) }

  before_create :set_date_added
  before_save :update_last_accessed

  def overdue?
    due_date.present? && due_date < Date.current
  end

  def checked_out?
    status == "checked_out"
  end

  def available_for_checkout?
    status == "available" && ownership_status == "owned"
  end

  def check_out_to(person, due_date = nil)
    return false unless available_for_checkout?
    
    update(
      status: :checked_out,
      lent_to: person,
      due_date: due_date || 2.weeks.from_now.to_date
    )
  end

  def check_in
    return false unless checked_out?
    
    update(
      status: :available,
      lent_to: nil,
      due_date: nil
    )
  end

  def update_condition(new_condition, notes = nil)
    update(
      condition: new_condition,
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
    return "Unknown" if condition.blank?
    condition.humanize
  end

  def tag_list
    tags&.split(",")&.map(&:strip) || []
  end

  def tag_list=(tag_array)
    self.tags = Array(tag_array).map(&:strip).reject(&:blank?).join(", ")
  end

  private

  def set_date_added
    self.date_added ||= Time.current
  end

  def update_last_accessed
    self.last_accessed = Time.current if changed? && !new_record?
  end
end
