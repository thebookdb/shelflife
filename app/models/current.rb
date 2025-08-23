class Current < ActiveSupport::CurrentAttributes
  attribute :session, :library
  delegate :user, to: :session, allow_nil: true
end
