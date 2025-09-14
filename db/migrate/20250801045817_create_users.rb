class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name
      t.boolean :admin, default: false, null: false
      t.json :user_settings, default: {}


      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
