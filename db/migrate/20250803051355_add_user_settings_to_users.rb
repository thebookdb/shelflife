class AddUserSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :user_settings, :json, default: {}
  end
end
