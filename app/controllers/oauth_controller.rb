class OauthController < ApplicationController
  before_action :require_authentication

  def tbdb
    oauth_service = Tbdb::OauthService.new

    begin
      authorization_url = oauth_service.authorization_url
      redirect_to authorization_url, allow_other_host: true
    rescue Tbdb::OauthService::OAuthError => e
      Rails.logger.error "OAuth initiation failed: #{e.message}"
      redirect_to profile_path, alert: "Failed to connect to TBDB: #{e.message}"
    end
  end

  def tbdb_callback
    code = params[:code]
    state = params[:state]
    error = params[:error]
    error_hint = params[:error_hint]

    if error.present?
      # Handle case where OAuth client is invalid/not found on TBDB
      if error == "invalid_client" && error_hint == "client_not_found"
        Rails.logger.info "OAuth client not found on TBDB, clearing credentials and re-registering"

        oauth_service = Tbdb::OauthService.new

        begin
          # Clear the invalid credentials
          oauth_service.clear_client_credentials

          # Redirect back to initiate OAuth flow, which will re-register
          redirect_to auth_tbdb_path, notice: "Re-registering with TBDB..."
          return
        rescue => e
          Rails.logger.error "Failed to handle client re-registration: #{e.message}"
          redirect_to profile_path, alert: "OAuth client not found. Please try connecting again."
          return
        end
      end

      Rails.logger.error "OAuth callback error: #{error} (hint: #{error_hint})"
      redirect_to profile_path, alert: "TBDB authorization failed: #{params[:error_description] || error}"
      return
    end

    if code.blank?
      redirect_to profile_path, alert: "No authorization code received from TBDB"
      return
    end

    oauth_service = Tbdb::OauthService.new

    begin
      oauth_service.exchange_code_for_token(code, state)
      redirect_to profile_path, notice: "Successfully connected to TBDB!"
    rescue Tbdb::OauthService::OAuthError => e
      Rails.logger.error "OAuth token exchange failed: #{e.message}"
      redirect_to profile_path, alert: "Failed to complete TBDB connection: #{e.message}"
    end
  end

  def tbdb_disconnect
    oauth_service = Tbdb::OauthService.new
    oauth_service.revoke_tokens
    redirect_to profile_path, notice: "Disconnected from TBDB"
  end
end