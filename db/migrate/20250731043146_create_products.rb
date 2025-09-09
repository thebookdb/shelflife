class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products, id: false do |t|
      t.string :id, primary_key: true, default: -> { "ULID()" }
      t.string :gtin, null: false
      t.boolean :valid_barcode, default: true
      t.string :title
      t.string :subtitle
      t.string :author
      t.string :publisher
      t.date :publication_date
      t.text :description
      t.string :cover_image_url
      t.integer :pages
      t.string :genre
      t.string :product_type, null: false
      t.json :tbdb_data

      t.timestamps
    end
    add_index :products, :gtin, unique: true
    add_index :products, :product_type
  end
end
