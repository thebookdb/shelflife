class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :scans, foreign_key: :user_id, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # User settings management
  def hide_invalid_barcodes?
    user_settings.fetch("hide_invalid_barcodes", false)
  end

  def update_setting(key, value)
    self.user_settings = user_settings.merge(key.to_s => value)
    save
  end

  def get_setting(key, default = nil)
    user_settings.fetch(key.to_s, default)
  end
end
