# Tbdb module namespace loader
# Ensures all Tbdb classes are available for autoloading

require_relative "tbdb/errors"

module Tbdb
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
