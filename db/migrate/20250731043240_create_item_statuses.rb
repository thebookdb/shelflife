class CreateItemStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :item_statuses do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :item_statuses, :name, unique: true
    add_index :item_statuses, :active
    
    # Create default statuses
    reversible do |dir|
      dir.up do
        ItemStatus.create!([
          { name: "Available", description: "Item is available for use/checkout" },
          { name: "Checked Out", description: "Item is currently checked out" },
          { name: "Missing", description: "Item cannot be located" },
          { name: "Damaged", description: "Item is damaged and needs repair" },
          { name: "In Repair", description: "Item is being repaired" },
          { name: "Retired", description: "Item is no longer in active circulation" }
        ])
      end
    end
  end
end
