class Library < ApplicationRecord
  has_many :library_items, foreign_key: :library_id, dependent: :destroy
  has_many :products, through: :library_items
  belongs_to :user, optional: true

  scope :for_user, ->(user) { where(user: [user, nil]).order(:position, :name) }

  validates :name, presence: true, uniqueness: true

  enum :visibility, {
    ours: 0,    # Only visible to users
    anyone: 1,  # Accessible via share token
    everyone: 2   # Publicly browsable and subscribable
  }

  enum :default_intent, {have: 0, want: 1}, prefix: :default

  before_create :set_default_position

  def self.default_libraries
    [
      {name: "Home", description: "Books and media at home"},
      {name: "Work", description: "Books and media at work"}
    ]
  end

  private

  def set_default_position
    self.position = (Library.where(user: user).maximum(:position) || 0) + 1
  end
end
