class CreateTbdbConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :tbdb_connections do |t|
      # OAuth app registration with TBDB
      t.string :client_id
      t.string :client_secret

      # OAuth access tokens for API calls
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
