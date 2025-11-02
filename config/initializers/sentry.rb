# Sentry Error Tracking
# Only initialize in production environment and only if DSN is configured
Rails.application.configure do
  if Rails.env.production? && ENV['SENTRY_DSN'].present?
    Sentry.init do |config|
      config.breadcrumbs_logger = [:active_support_logger, :http_logger]
      config.dsn = ENV['SENTRY_DSN']

      # Set the environment tag
      config.environment = Rails.env

      # Performance monitoring - enable with low sample rate
      config.traces_sample_rate = ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', 0.1).to_f

      # Filter out sensitive data
      config.send_default_pii = false

      # Filter out certain exceptions that are typically noise
      config.excluded_exceptions += [
        'ActionController::InvalidAuthenticityToken',
        'CGI::Session::CookieStore::TamperedWithCookie',
        'ActionController::UnknownFormat'
      ]
    end

    Rails.logger.info "Sentry initialized in production environment"
  end
end