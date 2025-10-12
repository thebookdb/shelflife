require_relative '../tbdb'

module ShelfLife
  class TbdbService
    attr_reader :client

    def initialize
      @client = get_or_create_client
    end

    # Delegate common methods to the TBDB client
    def get_product(product_id)
      client.get_product(product_id)
    end

    def search_products(query, options = {})
      client.search_products(query, options)
    end

    # Convenience class method
    def self.client
      new.client
    end

    private

    def get_or_create_client
      connection = TbdbConnection.instance

      # Create cache key based on connection status and updated timestamp
      # This ensures cache is invalidated when connection changes
      cache_key = "tbdb_client:#{connection.status}:#{connection.updated_at.to_i}"

      Rails.cache.fetch(cache_key, expires_in: 25.minutes) do
        Tbdb::Client.new
      end
    end
  end
end