class CreateLibraryItems < ActiveRecord::Migration[8.0]
  def change
    create_table :library_items do |t|
      t.references :product, null: false, foreign_key: true
      t.references :library, null: false, foreign_key: true
      t.string :condition
      t.string :location
      t.text :notes
      t.datetime :date_added, default: -> { "CURRENT_TIMESTAMP" }
      
      # Acquisition tracking
      t.date :acquisition_date
      t.string :acquisition_source
      t.decimal :acquisition_price, precision: 8, scale: 2
      t.string :ownership_status
      t.string :copy_identifier
      
      # Enhanced condition tracking
      t.text :condition_notes
      t.date :last_condition_check
      t.text :damage_description
      
      # Status and circulation
      t.string :status
      t.string :lent_to
      t.date :due_date
      
      # Value tracking
      t.decimal :replacement_cost, precision: 8, scale: 2
      t.decimal :original_retail_price, precision: 8, scale: 2
      t.decimal :current_market_value, precision: 8, scale: 2
      
      # Metadata
      t.text :private_notes
      t.string :tags
      t.datetime :last_accessed
      t.boolean :is_favorite, default: false

      t.timestamps
    end

    add_index :library_items, [ :product_id, :library_id ]
  end
end
