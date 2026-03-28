class Condition < ApplicationRecord
  has_many :library_items, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  default_scope { order(:sort_order, :name) }
end
