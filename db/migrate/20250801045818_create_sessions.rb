class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions, id: :string, default: -> { "ULID()" } do |t|
      t.string :user_id, null: false
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
    add_foreign_key :sessions, :users
    add_index :sessions, :user_id
  end
end
