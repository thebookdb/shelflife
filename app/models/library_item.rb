class LibraryItem < ApplicationRecord
  belongs_to :product, foreign_key: :product_id
  belongs_to :library, foreign_key: :library_id
  belongs_to :item_status, optional: true
  belongs_to :acquisition_source, optional: true
  belongs_to :ownership_status, optional: true

  validates :product_id, presence: true
  validates :library_id, presence: true
  validates :acquisition_price, :replacement_cost, :original_retail_price, :current_market_value,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :recent, -> { order(date_added: :desc) }
  scope :in_library, ->(library) { where(library: library) }
  scope :virtual_items, -> { joins(:library).where(libraries: { virtual: true }) }
  scope :physical_items, -> { joins(:library).where(libraries: { virtual: false }) }
  scope :wishlist_items, -> { joins(:library).where(libraries: { name: "Wishlist" }) }
  scope :owned_items, -> { joins(:library).where(libraries: { virtual: false }) }
  scope :favorites, -> { where(is_favorite: true) }
  scope :by_condition, ->(condition) { where(condition: condition) }
  scope :overdue, -> { where("due_date < ?", Date.current) }
  scope :with_status, ->(status_name) { joins(:item_status).where(item_statuses: { name: status_name }) }
  scope :available, -> { joins(:item_status).where(item_statuses: { name: "Available" }) }
  scope :checked_out, -> { joins(:item_status).where(item_statuses: { name: "Checked Out" }) }

  before_create :set_date_added
  before_save :update_last_accessed

  def overdue?
    due_date.present? && due_date < Date.current
  end

  def checked_out?
    item_status&.name == "Checked Out"
  end

  def available?
    item_status&.name == "Available"
  end

  def available_for_checkout?
    available? && ownership_status&.name == "Owned" && !virtual_item?
  end

  def virtual_item?
    library&.virtual?
  end

  def physical_item?
    !virtual_item?
  end

  def check_out_to(person, due_date = nil)
    return false unless available_for_checkout?
    return false if virtual_item?
    
    checked_out_status = ItemStatus.find_by(name: "Checked Out")
    return false unless checked_out_status
    
    update(
      item_status: checked_out_status,
      lent_to: person,
      due_date: due_date || 2.weeks.from_now.to_date
    )
  end

  def check_in
    return false unless checked_out?
    return false if virtual_item?
    
    available_status = ItemStatus.find_by(name: "Available")
    return false unless available_status
    
    update(
      item_status: available_status,
      lent_to: nil,
      due_date: nil
    )
  end

  def update_condition(new_condition, notes = nil)
    return false if virtual_item?
    
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
