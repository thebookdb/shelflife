class CreateAcquisitionSources < ActiveRecord::Migration[8.0]
  def change
    create_table :acquisition_sources do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :acquisition_sources, :name, unique: true
    add_index :acquisition_sources, :active
    
    # Create default acquisition sources
    reversible do |dir|
      dir.up do
        AcquisitionSource.create!([
          { name: "Purchased", description: "Bought from store or online" },
          { name: "Gift", description: "Received as a gift" },
          { name: "Borrowed", description: "Borrowed from someone" },
          { name: "Found", description: "Found item" },
          { name: "Inherited", description: "Inherited from family/estate" },
          { name: "Trade", description: "Traded for another item" },
          { name: "Review Copy", description: "Received for review purposes" }
        ])
      end
    end
  end
end
