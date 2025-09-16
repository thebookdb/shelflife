class ProductDataFetchJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 30.seconds, attempts: 3 do |job, error|
    Rails.logger.error("ProductDataFetchJob failed for product #{job.arguments.first&.gtin}: #{error.class} - #{error.message}")
    Rails.logger.error(error.backtrace&.first(10)&.join("\n"))
  end

  # Handle rate limit errors with intelligent rescheduling
  retry_on Tbdb::RateLimitError, wait: :exponential_longer, attempts: 5 do |job, error|
    product = job.arguments.first
    retry_time = error.reset_time || (Time.current + error.retry_after.seconds)

    Rails.logger.warn("ProductDataFetchJob rate limited for product #{product&.gtin}, rescheduling for #{retry_time}")

    # Update product with rate limit status
    if product
      product.update!(
        tbdb_data: {
          fetched_at: Time.current.iso8601,
          status: "rate_limited",
          message: "Rate limit exceeded, retrying at #{retry_time.iso8601}",
          retry_at: retry_time.iso8601
        }
      )
    end
  end

  discard_on ActiveJob::DeserializationError do |job, error|
    Rails.logger.error("ProductDataFetchJob discarded due to deserialization error: #{error.message}")
  end

  def perform(product, force = false)
    Rails.logger.info("Start product enrichment for #{product.gtin}")
    ProductEnrichmentService.new.call(product, force)
    Rails.logger.info("Finish product enrichment for #{product.gtin}")
  rescue => error
    Rails.logger.error("ProductDataFetchJob error for #{product.gtin}: #{error.class} - #{error.message}")
    Rails.logger.error(error.backtrace&.first(10)&.join("\n"))
    raise
  end
end
