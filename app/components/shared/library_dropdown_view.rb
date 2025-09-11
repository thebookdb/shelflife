class Components::Shared::LibraryDropdownView < Components::Base
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::FormWith

  def initialize(product:, button_text: "📚 Add to Libraries", button_class: nil)
    @product = product
    @button_text = button_text
    @button_class = button_class || "w-full bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors font-medium text-sm flex items-center justify-between"
    @libraries = Library.all
  end

  def view_template
    # Turbo frame for updating entire component
    turbo_frame(id: dom_id(@product, 'library_dropdown')) do
      div(
        class: "relative",
        data: { controller: "library-dropdown", "library-dropdown-product-id-value": @product.id }
      ) do
        # Dropdown button
        button(
          type: "button",
          data: { action: "click->library-dropdown#toggle" },
          class: @button_class
        ) do
          span { @button_text }
          span(class: "ml-2") { "▼" }
        end
        
        # Dropdown content using fixed positioning to escape overflow-hidden
        div(
          data: { "library-dropdown-target": "content" },
          class: "hidden fixed bg-white border border-gray-200 rounded-lg shadow-lg max-h-96 overflow-y-auto z-50"
        ) do
          div(data: { "library-dropdown-target": "snippet" }, id: 'library_dropdown_content') do
            div(class: "p-3") do
              div(class: "text-sm font-semibold text-gray-700 mb-2") { "Select libraries:" }
              
              @libraries.each do |library|
                render_library_checkbox(library)
              end
            end
          end
        end
      end
    end
  end

  private

  def render_library_checkbox(library)
    library_item = @product.library_items.find { |li| li.library == library } || LibraryItem.new(library: library, product: @product)
    is_in_library = library_item.persisted?
    
    div(class: "flex items-center gap-2 py-1") do
      form_with(
        model: library_item,
        url: "/library_items",
        method: :post,
        local: false,
        data: { controller: "library-form" },
        class: "flex items-center gap-2 w-full"
      ) do |f|
        f.hidden_field :product_id, value: @product.id
        f.hidden_field :library_id, value: library.id
        
        label(
          for: "library_item_exist_#{library.id}",
          class: "flex items-center gap-2 text-sm text-gray-700 cursor-pointer flex-1"
        ) do
          f.check_box(
            :exist,
            {
              id: "library_item_exist_#{library.id}",
              checked: is_in_library,
              data: { action: "change->library-form#submit" },
              class: "rounded border-gray-300 text-green-600 focus:ring-green-500"
            }
          )
          
          span { library.name }
          
          if library.description.present?
            span(class: "text-gray-400 text-xs ml-1") { " - #{library.description}" }
          end
        end
        
        span(class: "text-xs transition-opacity duration-500") do
          if is_in_library
            span(class: "text-green-600") { "✓ In library" }
          end
        end
      end
    end
  end
end