class RefactorLibrariesAndDropScans < ActiveRecord::Migration[8.1]
  def change
    # Add user_id to libraries (optional owner)
    add_column :libraries, :user_id, :integer, null: true
    add_index :libraries, :user_id
    add_foreign_key :libraries, :users, column: :user_id, on_delete: :nullify

    # Add tracking and intent columns to library_items
    add_column :library_items, :added_by_id, :integer, null: true
    add_column :library_items, :updated_by_id, :integer, null: true
    add_column :library_items, :intent, :integer, default: 0, null: false
    add_index :library_items, :added_by_id
    add_index :library_items, :updated_by_id
    add_index :library_items, :intent
    add_foreign_key :library_items, :users, column: :added_by_id, on_delete: :nullify
    add_foreign_key :library_items, :users, column: :updated_by_id, on_delete: :nullify

    # Remove virtual column from libraries
    remove_index :libraries, :virtual
    remove_column :libraries, :virtual, :boolean, default: false, null: false

    # Drop scans table
    drop_table :scans do |t|
      t.integer :product_id, null: false
      t.integer :user_id, null: false
      t.datetime :scanned_at, null: false
      t.timestamps
    end
  end
end
