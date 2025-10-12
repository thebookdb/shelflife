class TbdbConnection < ApplicationRecord
  # Singleton pattern - only one TBDB connection per ShelfLife instance
  # This connection is used for all TBDB API product data lookups

  VERIFICATION_TTL = 10.minutes

  def self.instance
    first_or_create!
  end

  # Check if OAuth app is registered with TBDB
  def registered?
    client_id.present? && client_secret.present?
  end

  # Check if we have valid access tokens and connection is not marked invalid
  def connected?
    access_token.present? && status == 'connected'
  end

  # Check if the OAuth token has expired
  def token_expired?
    return true if expires_at.nil?
    Time.current >= expires_at
  end

  # Check if connection was verified recently
  def verified?
    verified_at.present? && verified_at > VERIFICATION_TTL.ago
  end

  # Mark connection as verified
  def mark_verified!
    update!(
      status: 'connected',
      verified_at: Time.current,
      last_error: nil
    )
  end

  # Mark connection as invalid with error message
  def mark_invalid!(error_message)
    update!(
      status: 'invalid',
      last_error: error_message
    )
  end

  # Clear all OAuth credentials (for disconnect/reset)
  def clear_connection
    update!(
      access_token: nil,
      refresh_token: nil,
      expires_at: nil,
      status: 'connected',
      verified_at: nil,
      last_error: nil
    )
  end

  # Clear OAuth app registration (for re-registration scenarios)
  def clear_registration
    update!(
      client_id: nil,
      client_secret: nil,
      access_token: nil,
      refresh_token: nil,
      expires_at: nil,
      api_base_url: nil,
      status: 'connected',
      verified_at: nil,
      last_error: nil
    )
  end
end
