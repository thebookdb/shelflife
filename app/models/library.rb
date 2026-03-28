class Library < ApplicationRecord
  has_many :library_items, foreign_key: :library_id, dependent: :destroy
  has_many :products, through: :library_items
  belongs_to :user, optional: true

  validates :name, presence: true, uniqueness: true

  enum :visibility, {
    ours: 0,    # Only visible to users
    anyone: 1,  # Accessible via share token
    everyone: 2   # Publicly browsable and subscribable
  }

  def self.default_libraries
    [
      {name: "Home", description: "Books and media at home"},
      {name: "Work", description: "Books and media at work"}
    ]
  end
end
