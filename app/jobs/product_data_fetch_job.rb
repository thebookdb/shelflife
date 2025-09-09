class ProductDataFetchJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 30.seconds, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(product)
    ProductEnrichmentService.new.call(product)
  end
end
