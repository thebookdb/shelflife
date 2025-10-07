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

  # API token management
  def thebookdb_api_token
    get_setting("thebookdb_api_token")
  end

  def thebookdb_api_token=(token)
    update_setting("thebookdb_api_token", token.present? ? token.strip : nil)
  end

  def has_thebookdb_api_token?
    thebookdb_api_token.present?
  end

  def effective_thebookdb_api_token
    has_thebookdb_api_token? ? thebookdb_api_token : ENV["TBDB_API_TOKEN"]
  end

  # OAuth management
  def has_oauth_connection?
    oauth_client_id.present? && oauth_access_token.present?
  end

  def oauth_token_expired?
    oauth_expires_at.nil? || oauth_expires_at <= Time.current
  end

  def oauth_token_valid?
    has_oauth_connection? && !oauth_token_expired?
  end

  def effective_tbdb_token
    oauth_token_valid? ? oauth_access_token : effective_thebookdb_api_token
  end

  def clear_oauth_connection
    update!(
      oauth_access_token: nil,
      oauth_refresh_token: nil,
      oauth_expires_at: nil
    )
  end
end
