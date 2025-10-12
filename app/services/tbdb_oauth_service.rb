require "net/http"
require "json"
require "uri"
require "securerandom"

class TbdbOauthService
  class OAuthError < StandardError; end

  # OAuth endpoints (authorization, token exchange, etc.)
  TBDB_OAUTH_URL = ENV.fetch("TBDB_OAUTH_URL", "http://thebookdb.localhost:3000").freeze

  # API endpoints (for making authenticated API calls)
  TBDB_API_URL = ENV.fetch("TBDB_API_URI", "http://api.thebookdb.localhost:3000").freeze

  def initialize
    @connection = TbdbConnection.instance
  end

  # Step 1: Register OAuth client dynamically if needed
  def ensure_oauth_client
    return if @connection.registered?

    register_oauth_client
  end

  # Step 2: Generate authorization URL for user to visit
  def authorization_url
    ensure_oauth_client

    state = SecureRandom.hex(16)
    Rails.cache.write("oauth_state", state, expires_in: 10.minutes)

    params = {
      response_type: "code",
      client_id: @connection.client_id,
      redirect_uri: redirect_uri,
      state: state,
      scope: "data:read"
    }

    "#{TBDB_OAUTH_URL}/oauth/authorize?#{URI.encode_www_form(params)}"
  end

  # Step 3: Exchange authorization code for access token
  def exchange_code_for_token(code, state)
    # Verify state parameter
    cached_state = Rails.cache.read("oauth_state")
    raise OAuthError, "Invalid state parameter" if state != cached_state

    Rails.cache.delete("oauth_state")

    uri = URI("#{TBDB_OAUTH_URL}/oauth/token")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    request.body = JSON.generate({
      grant_type: "authorization_code",
      client_id: @connection.client_id,
      client_secret: @connection.client_secret,
      code: code,
      redirect_uri: redirect_uri
    })

    # Debug logging
    Rails.logger.debug "=== OAuth Token Exchange Debug ==="
    Rails.logger.debug "Client ID: #{@connection.client_id}"
    Rails.logger.debug "Redirect URI: #{redirect_uri}"
    Rails.logger.debug "Authorization Code: #{code[0..10]}..." # Only log first part for security
    Rails.logger.debug "Request Body: #{request.body}"

    response = make_http_request(uri, request)

    Rails.logger.debug "Response Status: #{response.code}"
    Rails.logger.debug "Response Body: #{response.body}"

    token_data = JSON.parse(response.body)

    if response.is_a?(Net::HTTPSuccess)
      store_tokens(token_data)
    else
      raise OAuthError, "Token exchange failed: #{token_data['error'] || response.message}"
    end
  end

  # Refresh access token using refresh token
  def refresh_access_token
    return false unless @connection.refresh_token.present?

    uri = URI("#{TBDB_OAUTH_URL}/oauth/token")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    request.body = JSON.generate({
      grant_type: "refresh_token",
      client_id: @connection.client_id,
      client_secret: @connection.client_secret,
      refresh_token: @connection.refresh_token
    })

    response = make_http_request(uri, request)

    if response.is_a?(Net::HTTPSuccess)
      token_data = JSON.parse(response.body)
      store_tokens(token_data)
      true
    else
      Rails.logger.error "OAuth token refresh failed: #{response.body}"
      false
    end
  end

  # Revoke OAuth tokens
  def revoke_tokens
    return unless @connection.access_token.present?

    uri = URI("#{TBDB_OAUTH_URL}/oauth/revoke")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    request.body = JSON.generate({
      client_id: @connection.client_id,
      client_secret: @connection.client_secret,
      token: @connection.access_token
    })

    make_http_request(uri, request)
    @connection.clear_connection
  end

  # Clear client credentials (for re-registration scenarios)
  def clear_client_credentials
    @connection.clear_registration
    Rails.logger.info "Cleared OAuth client credentials"
  end

  private

  def redirect_uri
    # Generate redirect URI at runtime to avoid host issues
    if Rails.env.development?
      "http://localhost:4001/auth/tbdb/callback"
    else
      "#{Rails.application.routes.url_helpers.root_url.chomp('/')}/auth/tbdb/callback"
    end
  end

  def register_oauth_client
    uri = URI("#{TBDB_OAUTH_URL}/oauth/register")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    client_name = "ShelfLife Instance"

    request.body = JSON.generate({
      client_name: client_name,
      redirect_uris: [redirect_uri], # Single redirect URI for this ShelfLife instance
      scope: "data:read",
      application_type: "web",
      token_endpoint_auth_method: "client_secret_post"
    })

    response = make_http_request(uri, request)

    if response.is_a?(Net::HTTPSuccess)
      client_data = JSON.parse(response.body)
      @connection.update!(
        client_id: client_data["client_id"],
        client_secret: client_data["client_secret"],
        api_base_url: TBDB_API_URL
      )
      Rails.logger.info "Registered OAuth client for ShelfLife instance with #{TBDB_API_URL}"
    else
      error_data = JSON.parse(response.body) rescue { "error" => response.message }
      raise OAuthError, "Client registration failed: #{error_data['error']}"
    end
  end

  def store_tokens(token_data)
    expires_at = if token_data["expires_in"]
      Time.current + token_data["expires_in"].to_i.seconds
    else
      1.hour.from_now # Default fallback
    end

    @connection.update!(
      access_token: token_data["access_token"],
      refresh_token: token_data["refresh_token"],
      expires_at: expires_at,
      api_base_url: TBDB_API_URL, # Ensure base URL is always set
      verified_at: Time.current # Mark as verified since we just got tokens
    )

    Rails.logger.info "Stored OAuth tokens for ShelfLife instance (#{TBDB_API_URL})"
  end

  def make_http_request(uri, request)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.request(request)
  end
end