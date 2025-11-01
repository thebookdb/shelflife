if ENV["SENTRY_DSN"].present?
  Rails.application.configure do
    config.sentry.dsn = ENV.fetch("SENTRY_DSN")
    config.sentry.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.sentry.send_default_pii = false

    # Set environment for Sentry
    config.sentry.environment = Rails.env

    # Enable Sentry in all environments except test
    config.sentry.enabled_environments = %w[development staging production]

    # Set sample rate for performance monitoring
    config.sentry.traces_sample_rate = 0.25 if Rails.env.production?
    config.sentry.traces_sample_rate = 1.0 if Rails.env.development?

    # Send session data
    config.sentry.send_sessions = true if Rails.env.production?
  end
end