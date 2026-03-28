class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :libraries, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def default_library
    libraries.first || Library.first || Library.create!(
      name: "#{name.presence || email_address.split("@").first}'s Library",
      description: "Default library",
      user: self
    )
  end

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

  # Get effective API token (environment variable takes precedence)
  def effective_thebookdb_api_token
    ENV["TBDB_API_TOKEN"]
  end
end
