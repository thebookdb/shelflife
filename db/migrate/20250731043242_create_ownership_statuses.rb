class CreateOwnershipStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :ownership_statuses do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :ownership_statuses, :name, unique: true
    add_index :ownership_statuses, :active
    
    # Create default ownership statuses
    reversible do |dir|
      dir.up do
        OwnershipStatus.create!([
          { name: "Owned", description: "Item is owned outright" },
          { name: "Borrowed", description: "Item is borrowed from someone" },
          { name: "On Loan", description: "Item is on loan to someone else" },
          { name: "Consignment", description: "Item is on consignment" }
        ])
      end
    end
  end
end
