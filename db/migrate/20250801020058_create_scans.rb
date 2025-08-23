class CreateScans < ActiveRecord::Migration[8.0]
  def change
    create_table :scans, id: false do |t|
      t.string :id, primary_key: true, default: -> { "ULID()" }
      t.string :product_id, null: false
      t.datetime :scanned_at, null: false

      t.timestamps
    end

    add_index :scans, :scanned_at
    add_index :scans, :product_id
  end
end
