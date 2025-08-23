class AddUserToScans < ActiveRecord::Migration[8.0]
  def change
    add_column :scans, :user_id, :string, null: false
    add_foreign_key :scans, :users, column: :user_id
    add_index :scans, :user_id
  end
end
