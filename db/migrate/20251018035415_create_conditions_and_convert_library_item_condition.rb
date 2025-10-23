class CreateConditionsAndConvertLibraryItemCondition < ActiveRecord::Migration[8.0]
  def change
    # Create conditions table
    create_table :conditions do |t|
      t.string :name, null: false
      t.text :description
      t.integer :sort_order, default: 0
      t.timestamps
    end

    add_index :conditions, :name, unique: true

    # Add condition_id to library_items
    add_reference :library_items, :condition, null: true, foreign_key: true

    # Migrate existing condition string values to new association
    reversible do |dir|
      dir.up do
        # Create conditions from existing unique values
        existing_conditions = LibraryItem.where.not(condition: [nil, '']).distinct.pluck(:condition)
        existing_conditions.each_with_index do |condition_name, index|
          Condition.create!(name: condition_name, sort_order: index)
        end

        # Update library_items to use new condition_id
        LibraryItem.where.not(condition: [nil, '']).find_each do |item|
          condition_record = Condition.find_by(name: item.condition)
          item.update_column(:condition_id, condition_record.id) if condition_record
        end
      end
    end

    # Remove old condition string column
    remove_column :library_items, :condition, :string
  end
end
