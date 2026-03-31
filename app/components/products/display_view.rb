class Components::Products::DisplayView < Components::Base
  include Phlex::Rails::Helpers::TurboStreamFrom
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def initialize(product:, libraries: [])
    @product = product
    @libraries = libraries.presence || Library.order(:position, :name)
  end

  def view_template
    # Subscribe to product updates - keep outside the frame content
    turbo_stream_from "product_#{@product.id}"

    # Main container with proper centering
    div(id: "product-container-#{@product.id}", data: {product_id: @product.id}, class: "max-w-5xl mx-auto px-4 sm:px-6 lg:px-8") do
      # Product information card
      div(class: "bg-white rounded-lg shadow-md overflow-hidden border-l-4 border-slate-400") do
        turbo_frame(id: "product-data") do
          render Components::Products::DisplayDataView.new(product: @product, libraries: @libraries)
        end
      end

      # Library status
      div(class: "mt-4") do
        current_library_items = @product.library_items.includes(:library)

        if current_library_items.any?
          p(class: "text-sm text-gray-700") do
            plain "You have a copy of this product in: "
            current_library_items.each_with_index do |item, i|
              plain ", " if i > 0
              a(href: library_item_path(item), class: "font-medium text-orange-600 hover:text-orange-800 hover:underline") { item.library.name }
              if item.want?
                plain " "
                span(class: "text-slate-500 text-xs bg-slate-100 px-1.5 py-0.5 rounded") { "wishlist" }
              end
            end
          end
        else
          p(class: "text-sm text-gray-500") { "This product is not in any of your libraries." }
        end
      end

      # Library management section
      div(class: "mt-4 bg-white rounded-lg shadow-md overflow-hidden") do
        div(class: "px-6 pt-4 pb-2") do
          h3(class: "text-lg font-medium text-gray-900") { "Add this product to a library" }
        end

        div(class: "px-6 pb-6") do
          render Components::Shared::LibraryDropdownView.new(product: @product)

          # Refresh and Delete Product Buttons
          div(class: "mt-4 pt-4 border-t border-gray-200 flex gap-2") do
            form(method: "post", action: refresh_product_path(@product), class: "inline") do
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
              button(
                type: "submit",
                class: "bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors text-sm"
              ) { "Refresh Data" }
            end

            form(method: "post", action: product_path(@product), class: "inline") do
              input(type: "hidden", name: "_method", value: "delete")
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
              button(
                type: "submit",
                class: "bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors text-sm",
                "data-confirm": "Are you sure? This will delete the product and all associated scans permanently."
              ) { "Delete Product" }
            end
          end
        end
      end
    end
  end
end
