class Components::Shared::LibraryChipsView < Components::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken

  HEADINGS = {
    move: {title: "Change Library", subtitle: "Move this product to another library"},
    add: {title: "Add to Library", subtitle: "Tap to add or remove"}
  }.freeze

  # mode: :move (library item context) or :add (product context)
  def initialize(libraries:, mode:, library_item: nil, product: nil)
    @libraries = libraries
    @mode = mode
    @library_item = library_item
    @product = product
    @current_library_ids = if library_item
      [library_item.library_id]
    elsif product
      product.library_items.map(&:library_id)
    else
      []
    end
  end

  def view_template
    have_libraries = @libraries.select(&:default_have?)
    want_libraries = @libraries.select(&:default_want?)

    div(class: "rounded-xl bg-gradient-to-br from-gray-50 to-slate-50 border border-gray-200 p-5") do
      heading = HEADINGS[@mode]
      div(class: "mb-4") do
        h3(class: "text-sm font-semibold text-gray-800") { heading[:title] }
        p(class: "text-xs text-gray-400 mt-0.5") { heading[:subtitle] }
      end

      div(class: "flex flex-wrap gap-6") do
        if have_libraries.any?
          div do
            div(class: "flex items-center gap-1.5 mb-2") do
              span(class: "text-xs") { "📦" }
              span(class: "text-xs font-semibold text-gray-500 uppercase tracking-wide") { "Owned" }
            end
            div(class: "flex flex-wrap gap-2") do
              have_libraries.each { |lib| render_chip(lib) }
            end
          end
        end

        if want_libraries.any?
          div do
            div(class: "flex items-center gap-1.5 mb-2") do
              span(class: "text-xs") { "✨" }
              span(class: "text-xs font-semibold text-gray-500 uppercase tracking-wide") { "Wish List" }
            end
            div(class: "flex flex-wrap gap-2") do
              want_libraries.each { |lib| render_chip(lib) }
            end
          end
        end
      end
    end
  end

  private

  def render_chip(library)
    active = @current_library_ids.include?(library.id)

    if active && @mode == :move
      render_current_chip(library)
    elsif active && @mode == :add
      if @current_library_ids.size > 1
        render_remove_chip(library)
      else
        render_current_chip(library)
      end
    else
      render_inactive_chip(library)
    end
  end

  def render_current_chip(library)
    classes = if library.default_have?
      "border-2 border-orange-400 bg-orange-50 text-orange-800 shadow-sm shadow-orange-200/50"
    else
      "border-2 border-slate-400 bg-slate-50 text-slate-700 shadow-sm shadow-slate-200/50"
    end

    span(class: "inline-flex items-center gap-1.5 px-3.5 py-2 rounded-full text-sm font-semibold #{classes}") do
      checkmark_icon
      plain library.name
    end
  end

  def render_remove_chip(library)
    classes = if library.default_have?
      "border-2 border-orange-400 bg-orange-50 text-orange-800 shadow-sm shadow-orange-200/50 hover:border-red-400 hover:bg-red-50 hover:text-red-700 group/chip"
    else
      "border-2 border-slate-400 bg-slate-50 text-slate-700 shadow-sm shadow-slate-200/50 hover:border-red-400 hover:bg-red-50 hover:text-red-700 group/chip"
    end

    library_item = @product.library_items.find { |li| li.library_id == library.id }
    form(action: library_item_path(library_item), method: "post", class: "inline") do
      input(type: "hidden", name: "_method", value: "delete")
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
      button(
        type: "submit",
        class: "inline-flex items-center gap-1.5 px-3.5 py-2 rounded-full text-sm font-semibold #{classes} cursor-pointer transition-all duration-150"
      ) do
        span(class: "group-hover/chip:hidden") { checkmark_icon }
        span(class: "hidden group-hover/chip:inline") { cross_icon }
        plain library.name
      end
    end
  end

  def render_inactive_chip(library)
    if @mode == :move
      form(action: library_item_path(@library_item), method: "post", class: "inline") do
        input(type: "hidden", name: "_method", value: "patch")
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        input(type: "hidden", name: "library_item[library_id]", value: library.id)
        input(type: "hidden", name: "library_item[intent]", value: library.default_intent)
        input(type: "hidden", name: "return_to", value: library_item_path(@library_item))
        inactive_button(library.name)
      end
    else
      form(action: "/library_items", method: "post", class: "inline") do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        input(type: "hidden", name: "library_item[product_id]", value: @product.id)
        input(type: "hidden", name: "library_item[library_id]", value: library.id)
        input(type: "hidden", name: "library_item[exist]", value: "1")
        inactive_button(library.name)
      end
    end
  end

  def inactive_button(label)
    button(
      type: "submit",
      class: "inline-flex items-center gap-1.5 px-3.5 py-2 rounded-full text-sm font-medium " \
             "border-2 border-dashed border-gray-300 bg-white text-gray-500 " \
             "hover:border-gray-400 hover:bg-gray-50 hover:text-gray-700 " \
             "transition-all duration-150 cursor-pointer"
    ) do
      plus_icon
      plain label
    end
  end

  def checkmark_icon
    svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 20 20", fill: "currentColor", class: "w-4 h-4") do |s|
      s.path(
        fill_rule: "evenodd",
        d: "M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z",
        clip_rule: "evenodd"
      )
    end
  end

  def plus_icon
    svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 20 20", fill: "currentColor", class: "w-3.5 h-3.5 opacity-40") do |s|
      s.path(d: "M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z")
    end
  end

  def cross_icon
    svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 20 20", fill: "currentColor", class: "w-4 h-4") do |s|
      s.path(
        d: "M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"
      )
    end
  end
end
