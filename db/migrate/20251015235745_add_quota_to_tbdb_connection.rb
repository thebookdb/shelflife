class AddQuotaToTbdbConnection < ActiveRecord::Migration[8.0]
  def change
    add_column :tbdb_connections, :quota_remaining, :integer
    add_column :tbdb_connections, :quota_limit, :integer
    add_column :tbdb_connections, :quota_percentage, :decimal
    add_column :tbdb_connections, :quota_reset_at, :datetime
    add_column :tbdb_connections, :quota_updated_at, :datetime
  end
end
