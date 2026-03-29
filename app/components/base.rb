# frozen_string_literal: true

class Components::Base < Phlex::HTML
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith
  include Rails.application.routes.url_helpers

  # Add Rails URL helpers with default options
  def default_url_options
    {host: "localhost", port: 3000}
  end

  register_element :turbo_frame
  register_element :turbo_cable_stream_source

  def intent_border_class(item)
    item&.have? ? "border-orange-500" : "border-slate-400"
  end

  def product_icon(product_type)
    case product_type
    when "book" then "📚"
    when "video" then "💿"
    when "ebook" then "📱"
    when "audiobook" then "🎧"
    when "toy" then "🧸"
    when "lego" then "🧱"
    when "pop" then "🎭"
    when "graphic_novel" then "📖"
    when "box_set" then "📦"
    when "music" then "🎵"
    when "ereader" then "📖"
    when "table_top_game" then "🎲"
    else "📦"
    end
  end

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
