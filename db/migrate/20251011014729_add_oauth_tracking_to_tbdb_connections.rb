class AddOauthTrackingToTbdbConnections < ActiveRecord::Migration[8.0]
  def change
    add_column :tbdb_connections, :api_base_url, :string
    add_column :tbdb_connections, :status, :string, default: 'connected'
    add_column :tbdb_connections, :verified_at, :datetime
    add_column :tbdb_connections, :last_error, :text
  end
end
