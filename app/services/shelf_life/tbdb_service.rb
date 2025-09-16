require_relative '../tbdb'

module ShelfLife
  class TbdbService
    attr_reader :client

    def initialize(user: nil)
      @user = user
      token = determine_api_token(user)
      @client = get_or_create_client(token, user)
    end

    # Delegate common methods to the TBDB client
    def get_product(product_id)
      client.get_product(product_id)
    end

    def search_products(query, options = {})
      client.search_products(query, options)
    end

    # Convenience class method that uses Current.user
    def self.current_user_client
      new(user: Current.user)
    end

    private

    def get_or_create_client(token, user)
      # Create a cache key based on user ID or 'system' for ENV token
      cache_key = if user&.id
        "tbdb_client:#{user.id}"
      else
        "tbdb_client:system"
      end

      Rails.cache.fetch(cache_key, expires_in: 25.minutes) do
        Tbdb::Client.new(api_token: token)
      end
    end

    def determine_api_token(user)
      if user&.respond_to?(:effective_thebookdb_api_token)
        user.effective_thebookdb_api_token
      else
        # Fallback to Current.user if no user provided, then ENV
        Current.user&.effective_thebookdb_api_token || ENV["TBDB_API_TOKEN"]
      end
    end
  end
end