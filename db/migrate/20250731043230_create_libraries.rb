class CreateLibraries < ActiveRecord::Migration[8.0]
  def change
    create_table :libraries do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :virtual, default: false, null: false
      t.integer :visibility, default: 0, null: false


      t.timestamps
    end
    add_index :libraries, :name, unique: true
    add_index :libraries, :virtual
    
    # Create default libraries
    reversible do |dir|
      dir.up do
        Library.create!([
          { name: "My Library", description: "Personal collection", virtual: false },
          { name: "Wishlist", description: "Items to acquire", virtual: true }
        ])
      end
    end
  end
end
