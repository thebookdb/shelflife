class Library < ApplicationRecord
  has_many :library_items, foreign_key: :library_id, dependent: :destroy
  has_many :products, through: :library_items

  validates :name, presence: true, uniqueness: true

  scope :physical_libraries, -> { where(virtual: false) }
  scope :virtual_libraries, -> { where(virtual: true) }
  scope :wishlist, -> { find_by(name: "Wishlist") }

  enum :visibility, {
    ours: 0,    # Only visible to users
    anyone: 1,  # Accessible via share token
    everyone: 2   # Publicly browsable and subscribable
  }

  def self.default_libraries
    [
      { name: "Home", description: "Books and media at home", virtual: false },
      { name: "Work", description: "Books and media at work", virtual: false },
      { name: "Wishlist", description: "Items I want to acquire", virtual: true }
    ]
  end

  def virtual?
    virtual
  end

  def wishlist?
    name == "Wishlist"
  end
end
