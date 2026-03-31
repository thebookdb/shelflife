class AddPositionToLibraries < ActiveRecord::Migration[8.1]
  def change
    add_column :libraries, :position, :integer, default: 0, null: false
  end
end
