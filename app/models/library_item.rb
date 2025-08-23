class LibraryItem < ApplicationRecord
  belongs_to :product, foreign_key: :product_id
  belongs_to :library, foreign_key: :library_id

  validates :product_id, presence: true
  validates :library_id, presence: true

  scope :recent, -> { order(date_added: :desc) }
  scope :in_library, ->(library) { where(library: library) }
  scope :wishlist_items, -> { joins(:library).where(libraries: { name: "Wishlist" }) }
  scope :owned_items, -> { joins(:library).where.not(libraries: { name: "Wishlist" }) }

  before_create :set_date_added

  private

  def set_date_added
    self.date_added ||= Time.current
  end
end
