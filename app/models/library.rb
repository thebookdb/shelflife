class Library < ApplicationRecord
  has_many :library_items, foreign_key: :library_id, dependent: :destroy
  has_many :products, through: :library_items

  validates :name, presence: true, uniqueness: true

  scope :user_libraries, -> { where.not(name: "Wishlist") }
  scope :wishlist, -> { find_by(name: "Wishlist") }

  def self.default_libraries
    [
      { name: "Home", description: "Books and media at home" },
      { name: "Work", description: "Books and media at work" },
      { name: "Wishlist", description: "Items I want to acquire" }
    ]
  end

  def wishlist?
    name == "Wishlist"
  end
end
