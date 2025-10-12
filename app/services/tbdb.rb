require "net/http"
require "json"
require "uri"

module Tbdb
  class RateLimitError < StandardError
    attr_accessor :reset_time, :retry_after
  end

  class QuotaExhaustedError < StandardError
    attr_accessor :reset_time, :retry_after
  end

  class AuthenticationError < StandardError
  end

  class ConnectionRequiredError < StandardError
  end

  class Client
    VERSION = "0.3"

    # Fallback base URI if connection doesn't specify one
    DEFAULT_BASE_URI = ENV.fetch("TBDB_API_URI", "https://api.thebookdb.info").freeze

    attr_reader :jwt_token, :jwt_expires_at, :base_uri, :last_request_time, :calculated_delay

    def initialize(base_uri: nil)
      @connection = TbdbConnection.instance
      @last_request_time = nil
      @calculated_delay = nil

      # Ensure we have a valid OAuth connection
      ensure_oauth_connected!

      # Use connection's base URL (set during OAuth), or fallback
      effective_base_uri = base_uri || @connection.api_base_url || DEFAULT_BASE_URI
      @base_uri = URI(effective_base_uri)

      # Verify base URI matches connection's base URI
      verify_base_uri_match!

      # Load JWT from OAuth (access token IS the JWT)
      load_jwt_from_oauth
    end

    def user_agent
      "ShelfLife-Bot/#{VERSION} (#{Rails.application.class.module_parent_name})"
    end

    # Main API methods
    def get_product(product_id)
      make_request("/api/v1/products/#{product_id}")
    end

    def search_products(query, options = {})
      params = { q: query }
      params[:ptype] = options[:product_type] if options[:product_type]
      params[:per_page] = [options[:per_page] || 20, 100].min
      params[:page] = [options[:page] || 1, 1].max

      make_request("/search", method: :get, params: params)
    end

    def create_product(product_data)
      make_request("/api/v1/products", method: :post, params: product_data)
    end

    def update_product(product_id, product_data)
      make_request("/api/v1/products/#{product_id}", method: :patch, params: product_data)
    end

    def get_me
      make_request("/api/v1/me")
    end

    private

    def ensure_oauth_connected!
      # Check if connection is marked as invalid
      if @connection.status == 'invalid'
        error_msg = @connection.last_error || "TBDB connection is invalid. Please reconnect at /profile"
        Rails.logger.error "TBDB connection invalid: #{error_msg}"
        raise ConnectionRequiredError, error_msg
      end

      # Check if we have OAuth tokens
      unless @connection.access_token.present?
        error_msg = "No TBDB OAuth connection. Please connect at /profile"
        Rails.logger.error error_msg
        raise ConnectionRequiredError, error_msg
      end

      # Check if token is expired
      if @connection.token_expired?
        Rails.logger.debug "OAuth token expired, attempting refresh..."
        refresh_oauth_token
      end
    end

    def verify_base_uri_match!
      # Warn if using different base URI than what connection was registered with
      if @connection.api_base_url.present? && @connection.api_base_url != @base_uri.to_s
        Rails.logger.warn "⚠️  Base URI mismatch: connection=#{@connection.api_base_url}, client=#{@base_uri}"
      end
    end

    def load_jwt_from_oauth
      # OAuth access tokens ARE JWTs - use directly
      @jwt_token = @connection.access_token
      @jwt_expires_at = @connection.expires_at

      Rails.logger.debug "Using OAuth JWT (expires at #{@jwt_expires_at})"
    end

    def refresh_oauth_token
      oauth_service = TbdbOauthService.new

      if oauth_service.refresh_access_token
        # Reload connection to get fresh token
        @connection.reload
        @jwt_token = @connection.access_token
        @jwt_expires_at = @connection.expires_at
        Rails.logger.debug "OAuth token refreshed successfully"
      else
        error_msg = "Failed to refresh OAuth token. Please reconnect at /profile"
        @connection.mark_invalid!(error_msg)
        Rails.logger.error error_msg
        raise AuthenticationError, error_msg
      end
    end

    def make_request(path, method: :get, params: {}, retry_count: 0)
      # Check if token needs refresh before making request
      if @connection.token_expired?
        refresh_oauth_token
      end

      throttle_request

      # Ensure path starts with /
      api_path = path.start_with?("/") ? path : "/#{path}"
      uri = URI.join(@base_uri.to_s.chomp("/") + "/", api_path.sub(/^\//, ""))

      # Add query parameters for GET requests
      if method == :get && params.any?
        uri.query = URI.encode_www_form(params)
      end

      Rails.logger.debug "TBDB API Request: #{method.upcase} #{uri}"

      # Create request object
      request = case method
      when :get then Net::HTTP::Get.new(uri)
      when :post then Net::HTTP::Post.new(uri)
      when :patch then Net::HTTP::Patch.new(uri)
      when :delete then Net::HTTP::Delete.new(uri)
      else raise ArgumentError, "Unsupported HTTP method: #{method}"
      end

      # Set headers with OAuth JWT
      request["Authorization"] = "Bearer #{@jwt_token}"
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request["User-Agent"] = user_agent

      # Add body for non-GET requests
      if method != :get && params.any?
        request.body = JSON.generate(params)
      end

      # Make the request
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      response = http.request(request)
      @last_request_time = Time.now

      # Extract rate limit and quota info from headers
      store_rate_limit_info(response)
      check_quota_status(response)

      # Handle response
      handle_response(response, path, method, params, retry_count)
    end

    def handle_response(response, path, method, params, retry_count)
      case response
      when Net::HTTPSuccess
        return {} if response.body.nil? || response.body.empty?

        begin
          parsed_body = JSON.parse(response.body)
          # Extract quota from response body if present (e.g., from /me endpoint)
          check_quota_from_body(parsed_body)
          parsed_body
        rescue JSON::ParserError => e
          Rails.logger.error "Failed to parse TBDB API response as JSON: #{e.message}"
          nil
        end

      when Net::HTTPUnauthorized # 401
        handle_401_error(response)

      else
        # Handle other status codes
        case response.code
        when "429"
          handle_429_response(response, path, method, params, retry_count)
        when "503"
          handle_503_response(response)
        else
          Rails.logger.error "TBDB API request failed: #{response.code} - #{response.message}"
          log_error_details(response)
          nil # Return nil for other errors (404, 400, etc.)
        end
      end
    end

    def handle_401_error(response)
      Rails.logger.error "TBDB API request failed: 401 - Unauthorized"
      log_error_details(response)

      # Mark OAuth connection as invalid
      error_msg = if @connection.api_base_url.present? && @connection.api_base_url != @base_uri.to_s
        "OAuth tokens from #{@connection.api_base_url} cannot access #{@base_uri}. Please reconnect to the correct TBDB instance."
      else
        "OAuth tokens are invalid or expired. Please reconnect to TBDB."
      end

      Rails.logger.error "Marking OAuth connection as invalid: #{error_msg}"
      @connection.mark_invalid!(error_msg)

      # Clear cached clients
      Rails.cache.delete_matched("tbdb_client:*")

      raise AuthenticationError, error_msg
    end

    def log_error_details(response)
      begin
        error_data = JSON.parse(response.body)
        Rails.logger.error "Error details: #{error_data.inspect}"
      rescue JSON::ParserError
        Rails.logger.error "Response: #{response.body}"
      end
    end

    def throttle_request
      return unless @last_request_time

      # Use dynamic delay from headers, fallback to 1.1s
      min_interval = @calculated_delay || 1.1

      time_since_last = Time.now - @last_request_time
      if time_since_last < min_interval
        sleep_time = min_interval - time_since_last
        Rails.logger.debug "Throttling request: sleeping #{sleep_time.round(2)}s (interval: #{min_interval}s)"
        sleep(sleep_time)
      end
    end

    def calculate_backoff_time(retry_count)
      # Exponential backoff: 2^retry_count + 1 second (1s buffer for rate limit)
      base_wait = 2 ** retry_count
      base_wait + 1
    end

    def store_rate_limit_info(response)
      limit = response["X-RateLimit-Limit"]&.to_f
      window = response["X-RateLimit-Window"]&.to_f

      if limit && window && limit > 0
        @calculated_delay = window / limit
        Rails.logger.debug "Rate limit extracted: #{limit} requests per #{window}s = #{@calculated_delay}s delay"
      end
    end

    def check_quota_status(response)
      remaining = response["X-Quota-Remaining"]&.to_i
      limit = response["X-Quota-Limit"]&.to_i
      reset_time = response["X-Quota-Reset"]&.to_i

      if remaining && limit && remaining > 0
        store_quota_in_cache(remaining, limit, reset_time)
      end
    end

    def check_quota_from_body(body)
      # Extract quota from /me endpoint response body
      return unless body.is_a?(Hash) && body["rate_limits"]

      rate_limits = body["rate_limits"]
      limits = rate_limits["limits"] || {}
      usage = rate_limits["usage"] || {}

      quota_max = limits["quota_max"]
      current_usage = usage["current_quota"] || 0

      if quota_max
        remaining = quota_max - current_usage
        # quota_window is in seconds, end of window is now + window duration
        reset_time = Time.now.to_i + (limits["quota_window"] || 86400)
        Rails.logger.debug "Extracted quota from response body: #{remaining}/#{quota_max}"
        store_quota_in_cache(remaining, quota_max, reset_time)
      end
    end

    def store_quota_in_cache(remaining, limit, reset_time)
      # Handle division by zero and calculate percentage
      percentage = if limit && limit > 0
        (remaining.to_f / limit * 100).round(1)
      else
        0.0
      end

      Rails.logger.debug "TBDB quota: #{remaining}/#{limit || 'unknown'} remaining (#{percentage}%)"

      # Cache quota info for display in UI
      quota_data = {
        remaining: remaining,
        limit: limit,
        percentage: percentage,
        reset_at: reset_time ? Time.at(reset_time) : nil,
        updated_at: Time.now
      }

      # Store in cache with single shared key for entire instance
      Rails.cache.write("tbdb_quota_status:default", quota_data, expires_in: 1.hour)

      if remaining == 0
        Rails.logger.error "❌ TBDB quota exhausted: #{remaining}/#{limit || 'unknown'} remaining"
      elsif limit && limit > 0 && remaining < (limit * 0.1)
        Rails.logger.warn "⚠️  TBDB quota low: #{remaining}/#{limit} remaining (#{percentage}%)"
      end
    end

    def handle_429_response(response, path, method, params, retry_count)
      retry_after = response["Retry-After"]&.to_i || 60
      reset_time_header = response["X-Quota-Reset"]&.to_i

      # Check if this is quota exhaustion (long retry) vs rate limit (short retry)
      if retry_after > 60 # Quota exhausted
        error = QuotaExhaustedError.new("TBDB daily quota exhausted")
        error.reset_time = reset_time_header ? Time.at(reset_time_header) : (Time.now + retry_after)
        error.retry_after = retry_after

        Rails.logger.error "TBDB quota exhausted. Resets at #{error.reset_time}. Retry in #{retry_after}s"
        raise error
      elsif retry_count < 3 # Rate limit, retry with backoff
        wait_time = calculate_backoff_time(retry_count)
        Rails.logger.warn "Rate limited (429), retrying in #{wait_time}s (attempt #{retry_count + 1}/3)"

        sleep(wait_time)
        return make_request(path, method: method, params: params, retry_count: retry_count + 1)
      else # Rate limit but out of retries
        error = RateLimitError.new("TBDB API rate limit exceeded after #{retry_count + 1} attempts")
        error.retry_after = retry_after
        error.reset_time = reset_time_header ? Time.at(reset_time_header) : nil

        Rails.logger.error "Rate limit exceeded after #{retry_count + 1} attempts"
        raise error
      end
    end

    def handle_503_response(response)
      # Parse retry time from response body (e.g., "service unavailable: Retry in 600")
      retry_after = 600 # Default to 10 minutes

      begin
        body = response.body
        if body =~ /Retry in (\d+)/
          retry_after = $1.to_i
        end
      rescue
        # Use default if parsing fails
      end

      error = QuotaExhaustedError.new("TBDB service unavailable")
      error.reset_time = Time.now + retry_after
      error.retry_after = retry_after

      Rails.logger.error "TBDB service unavailable (503). Retry in #{retry_after}s (#{(retry_after / 60.0).round(1)} minutes)"
      raise error
    end
  end

  # Convenience method for creating a client instance
  def self.client
    @client ||= Client.new
  end

  # Convenience methods that use the default client
  def self.get_product(product_id)
    client.get_product(product_id)
  end

  def self.search_products(query, options = {})
    client.search_products(query, options)
  end

  # Retrieve cached quota status for the instance
  def self.quota_status
    Rails.cache.read("tbdb_quota_status:default")
  end
end
