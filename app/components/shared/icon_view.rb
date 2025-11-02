# frozen_string_literal: true

class Components::Shared::IconView < Phlex::SVG
  def initialize(name:, **attributes)
    @name = name
    @attributes = attributes
  end

  def view_template
    svg(**default_attributes.merge(@attributes)) do
      case @name
      when :check
        path(fill_rule: "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z", clip_rule: "evenodd")
      else
        raise ArgumentError, "Unknown icon: #{@name}"
      end
    end
  end

  private

  def default_attributes
    {
      fill: "currentColor",
      viewBox: "0 0 20 20",
      class: "w-5 h-5"
    }
  end
end