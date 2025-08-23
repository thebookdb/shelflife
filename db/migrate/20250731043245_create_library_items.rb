class CreateLibraryItems < ActiveRecord::Migration[8.0]
  def change
    create_table :library_items, id: false do |t|
      t.string :id, primary_key: true, default: -> { "ULID()" }
      t.string :product_id, null: false
      t.string :library_id, null: false
      t.string :condition
      t.string :location
      t.text :notes
      t.datetime :date_added, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_foreign_key :library_items, :products, column: :product_id
    add_foreign_key :library_items, :libraries, column: :library_id
    add_index :library_items, :product_id
    add_index :library_items, :library_id
    add_index :library_items, [ :product_id, :library_id ]
  end
end
