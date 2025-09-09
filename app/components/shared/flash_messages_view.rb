# frozen_string_literal: true

class Components::Shared::FlashMessagesView < Components::Base
  include Phlex::Rails::Helpers::Flash

  def view_template
    return unless flash.any?

    div(class: "fixed top-20 left-1/2 transform -translate-x-1/2 z-40 max-w-md w-full px-4") do
      flash.each do |type, message|
        div(class: flash_classes(type)) do
          message
        end
      end
    end
  end

  private

  def flash_classes(type)
    base_classes = "px-4 py-3 rounded-md text-sm font-medium"
    
    case type.to_s
    when "notice"
      "#{base_classes} bg-green-50 text-green-700 border border-green-200"
    when "alert"
      "#{base_classes} bg-red-50 text-red-700 border border-red-200"
    when "error"
      "#{base_classes} bg-red-50 text-red-700 border border-red-200"
    else
      "#{base_classes} bg-blue-50 text-blue-700 border border-blue-200"
    end
  end
end