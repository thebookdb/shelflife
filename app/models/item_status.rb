class ItemStatus < ApplicationRecord
  has_many :library_items, dependent: :restrict_with_error
  
  validates :name, presence: true, uniqueness: true
  validates :active, inclusion: { in: [true, false] }
  
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
end
