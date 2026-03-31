class Components::Libraries::ProductGroupView < Components::Base
  def initialize(product:, library_items:, library:)
    @product = product
    @library_items = library_items
    @library = library
  end

  def view_template
    @library_items.each do |item|
      render_item_card(item)
    end
  end

  private

  def render_item_card(item)
    a(href: library_item_path(item), class: "block rounded-lg border-l-4 #{intent_border_class(item)} bg-white shadow-sm hover:shadow-md transition-shadow px-4 py-3") do
      p(class: "font-medium text-gray-900 truncate") { @product.safe_title }
      div(class: "flex items-center justify-between gap-2 mt-1") do
        if @product.author.present?
          span(class: "text-xs text-gray-500 truncate") { @product.author }
        end
        if item.date_added.present?
          span(class: "text-xs text-gray-400 whitespace-nowrap") { item.date_added.strftime("%-d %b %Y") }
        end
      end
    end
  end
end
