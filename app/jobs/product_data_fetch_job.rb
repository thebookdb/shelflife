class ProductDataFetchJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "tbdb_api"

  # Handle rate limit errors - use the retry_after from the API
  retry_on Tbdb::RateLimitError, attempts: 5 do |job, error|
    product = job.arguments.first
    retry_after = error.retry_after || 60
    retry_time = error.reset_time || (Time.current + retry_after.seconds)

    Rails.logger.warn("ProductDataFetchJob rate limited for product #{product&.gtin}, retrying in #{retry_after}s")

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

    # Reschedule based on API's retry_after value
    job.retry_job(wait: retry_after.seconds)
  end

  # Handle quota exhaustion - reschedule for when quota resets
  retry_on Tbdb::QuotaExhaustedError, attempts: 10 do |job, error|
    product = job.arguments.first
    retry_after = error.retry_after || 3600 # Default to 1 hour if not specified
    retry_time = error.reset_time || (Time.current + retry_after.seconds)

    Rails.logger.warn("TBDB quota exhausted, rescheduling #{product&.gtin} for #{retry_after}s (#{retry_time})")

    # Update product with quota status
    if product
      product.update!(
        tbdb_data: {
          fetched_at: Time.current.iso8601,
          status: "quota_exhausted",
          message: "Daily quota exhausted, retrying at #{retry_time.iso8601}",
          retry_at: retry_time.iso8601
        }
      )
    end

    # Reschedule when quota resets
    job.retry_job(wait: retry_after.seconds)
  end

  # Handle authentication errors - discard job and mark product
  discard_on Tbdb::AuthenticationError do |job, error|
    product = job.arguments.first
    Rails.logger.error("TBDB authentication failed for #{product&.gtin}: #{error.message}")

    if product
      product.update!(
        tbdb_data: {
          fetched_at: Time.current.iso8601,
          status: "authentication_failed",
          message: "TBDB authentication failed. Please reconnect to TBDB.",
          error: error.message
        }
      )
    end
  end

  # Handle connection required errors - discard job and mark product
  discard_on Tbdb::ConnectionRequiredError do |job, error|
    product = job.arguments.first
    Rails.logger.error("TBDB connection required for #{product&.gtin}: #{error.message}")

    if product
      product.update!(
        tbdb_data: {
          fetched_at: Time.current.iso8601,
          status: "authentication_failed",
          message: error.message,
          error: error.message
        }
      )
    end
  end

  discard_on ActiveJob::DeserializationError do |job, error|
    Rails.logger.error("ProductDataFetchJob discarded due to deserialization error: #{error.message}")
  end

  def perform(product, force = false)
    Rails.logger.info("Start product enrichment for #{product.gtin} (job_id: #{job_id})")
    ProductEnrichmentService.new.call(product, force)
    Rails.logger.info("Finish product enrichment for #{product.gtin} (job_id: #{job_id})")
  rescue => error
    Rails.logger.error("ProductDataFetchJob error for #{product.gtin} (job_id: #{job_id}): #{error.class} - #{error.message}")
    Rails.logger.error(error.backtrace&.first(10)&.join("\n"))
    raise
  end
end
