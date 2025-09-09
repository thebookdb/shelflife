class CreateScans < ActiveRecord::Migration[8.0]
  def change
    create_table :scans do |t|
      t.references :product, null: false, foreign_key: true
      t.datetime :scanned_at, null: false

      t.timestamps
    end

    add_index :scans, :scanned_at
  end
end
