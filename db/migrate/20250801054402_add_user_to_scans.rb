class AddUserToScans < ActiveRecord::Migration[8.0]
  def change
    add_reference :scans, :user, null: false, foreign_key: true
  end
end
