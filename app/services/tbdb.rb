# Tbdb module namespace loader
# Ensures all Tbdb classes are available for autoloading

module Tbdb
  # Error classes
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

  # Retrieve quota status from the connection
  def self.quota_status
    TbdbConnection.instance.quota_status
  end
end
