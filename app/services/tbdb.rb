require "net/http"
require "json"
require "uri"

module TBDB
  class Client
    VERSION = "0.3"

    # Use production TBDB API by default (will move to api.tbdb.info soon)
    DEFAULT_BASE_URI = ENV.fetch("TBDB_API_URI", "https://api.thebookdb.info").freeze

    attr_reader :api_token, :jwt_token, :jwt_expires_at, :base_uri

    def initialize(api_token: ENV["TBDB_API_TOKEN"], base_uri: DEFAULT_BASE_URI)
      @api_token = api_token
      @base_uri = URI(base_uri)
      @jwt_token = nil
      @jwt_expires_at = nil

      validate_api_token!
      ensure_valid_jwt
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
      params[:per_page] = [ options[:per_page] || 20, 100 ].min
      params[:page] = [ options[:page] || 1, 1 ].max

      make_request("/search", method: :get, params: params)
    end

    def create_product(product_data)
      make_request("/api/v1/products", method: :post, params: product_data)
    end

    def update_product(product_id, product_data)
      make_request("/api/v1/products/#{product_id}", method: :patch, params: product_data)
    end

    private

    def validate_api_token!
      if @api_token.nil? || @api_token.empty?
        raise ArgumentError, "TBDB_API_TOKEN environment variable is required"
      end
    end

    def ensure_valid_jwt
      if jwt_needs_refresh?
        Rails.logger.debug "JWT missing or expired, exchanging for new token..."
        exchange_token_for_jwt
      else
        Rails.logger.debug "Using cached JWT token"
      end
    end

    def jwt_needs_refresh?
      @jwt_token.nil? || @jwt_expires_at.nil? || Time.now >= @jwt_expires_at
    end

    def exchange_token_for_jwt
      uri = URI.join(@base_uri.to_s.chomp("/") + "/", "api/tokens/exchange")

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_token}"
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request["User-Agent"] = user_agent

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        @jwt_token = data["access_token"]
        expires_in = data["expires_in"] || 1800  # Default to 30 minutes
        @jwt_expires_at = Time.now + expires_in - 60  # Refresh 1 minute early

        Rails.logger.debug "JWT token obtained, expires in #{expires_in} seconds"
        true
      else
        Rails.logger.error "Failed to exchange API token for JWT: #{response.code} - #{response.message}"
        begin
          error_data = JSON.parse(response.body)
          Rails.logger.error "Error details: #{error_data.inspect}"
        rescue JSON::ParserError
          Rails.logger.error "Response: #{response.body}"
        end
        raise StandardError, "Failed to obtain JWT token from TBDB API"
      end
    end

    def make_request(path, method: :get, params: {})
      ensure_valid_jwt

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

      # Set headers
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

      # Handle response
      if response.is_a?(Net::HTTPSuccess)
        return {} if response.body.nil? || response.body.empty?

        begin
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          Rails.logger.error "Failed to parse TBDB API response as JSON: #{e.message}"
          nil
        end
      else
        Rails.logger.error "TBDB API request failed: #{response.code} - #{response.message}"
        begin
          error_data = JSON.parse(response.body)
          Rails.logger.error "Error details: #{error_data.inspect}"
        rescue JSON::ParserError
          Rails.logger.error "Response: #{response.body}"
        end
        nil
      end
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
end
