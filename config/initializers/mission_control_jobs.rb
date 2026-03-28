# Mission Control Jobs configuration - must be set BEFORE mission control loads
# Set this as early as possible in the initialization process
MissionControl::Jobs.base_controller_class = "::ApplicationController"

# Fix for ActiveJob.queues method not being available
# Ensure mission control extensions are loaded after ActiveJob is loaded
Rails.application.config.after_initialize do
  if defined?(ActiveJob) && defined?(ActiveJob::Querying::Root)
    ActiveJob.extend ActiveJob::Querying::Root
  end
end
