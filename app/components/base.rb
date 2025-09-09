# frozen_string_literal: true

class Components::Base < Phlex::HTML
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith
  include Rails.application.routes.url_helpers
  
  # Add Rails URL helpers with default options
  def default_url_options
    { host: 'localhost', port: 3000 }
  end

  register_element :turbo_frame

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
