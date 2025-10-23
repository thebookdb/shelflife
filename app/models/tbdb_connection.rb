class TbdbConnection < ApplicationRecord
  # Singleton pattern - only one TBDB connection per ShelfLife instance
  # This connection is used for all TBDB API product data lookups
  # See app/services/tbdb for tbdb client, oauth service and error definitions.
  
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
      last_error: error_message,
      quota_remaining: nil,
      quota_limit: nil,
      quota_percentage: nil,
      quota_reset_at: nil,
      quota_updated_at: nil
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
      last_error: nil,
      quota_remaining: nil,
      quota_limit: nil,
      quota_percentage: nil,
      quota_reset_at: nil,
      quota_updated_at: nil
    )
  end

  # Update quota information from API response
  def update_quota(remaining:, limit:, reset_at: nil)
    percentage = if limit && limit > 0
      (remaining.to_f / limit * 100).round(1)
    else
      0.0
    end

    update!(
      quota_remaining: remaining,
      quota_limit: limit,
      quota_percentage: percentage,
      quota_reset_at: reset_at,
      quota_updated_at: Time.current
    )
  end

  # Clear quota information (when connection becomes invalid)
  def clear_quota
    update!(
      quota_remaining: nil,
      quota_limit: nil,
      quota_percentage: nil,
      quota_reset_at: nil,
      quota_updated_at: nil
    )
  end

  # Get quota status as a hash (for compatibility with cached format)
  def quota_status
    return nil unless quota_remaining && quota_limit

    {
      remaining: quota_remaining,
      limit: quota_limit,
      percentage: quota_percentage,
      reset_at: quota_reset_at,
      updated_at: quota_updated_at
    }
  end
end
