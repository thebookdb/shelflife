class CreateLibraries < ActiveRecord::Migration[8.0]
  def change
    create_table :libraries, id: false do |t|
      t.string :id, primary_key: true, default: -> { "ULID()" }
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
    add_index :libraries, :name, unique: true
  end
end
