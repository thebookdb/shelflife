class AddDefaultIntentToLibraries < ActiveRecord::Migration[8.1]
  def change
    add_column :libraries, :default_intent, :integer, default: 0, null: false
  end
end
