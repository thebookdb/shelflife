class CreateLibraryItems < ActiveRecord::Migration[8.0]
  def change
    create_table :library_items do |t|
      t.references :product, null: false, foreign_key: true
      t.references :library, null: false, foreign_key: true
      t.string :condition
      t.string :location
      t.text :notes
      t.datetime :date_added, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :library_items, [ :product_id, :library_id ]
  end
end
