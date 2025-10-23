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
end
