class Components::Products::DisplayView < Components::Base
  include Phlex::Rails::Helpers::TurboStreamFrom
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def initialize(product:, libraries: [])
    @product = product
    @libraries = libraries.presence || Library.all
  end

  def view_template
    # Subscribe to product updates - keep outside the frame content
    turbo_stream_from "product_#{@product.id}"

    # Main container that won't be replaced
    div(id: "product-container-#{@product.id}", data: { product_id: @product.id }) do
      div(class: "bg-white rounded-lg shadow-md overflow-hidden") do
        # Product data section - uses DisplayDataView for consistency
        turbo_frame(id: "product-data") do
          render Components::Products::DisplayDataView.new(product: @product, libraries: @libraries)
        end

        # Interactive Management Section - Separated with distinct styling
        div(class: "bg-gray-50 border-t border-gray-200") do
          # Section Header
          div(class: "px-6 pt-4 pb-2") do
            h3(class: "text-lg font-medium text-gray-900") { "Library Management" }
          end

          # Current Library Status
          div(class: "px-6 pb-4") do
            current_library_items = @product.library_items.includes(:library)

            if current_library_items.any?
              div(class: "bg-white border border-green-200 rounded-lg p-4") do
                h4(class: "text-sm font-semibold text-green-800 mb-3") { "In Your Libraries:" }
                div(class: "space-y-2") do
                  current_library_items.each do |item|
                    div(class: "flex justify-between items-center text-sm") do
                      a(href: library_path(item.library), class: "text-green-700 hover:text-green-900 hover:underline font-medium", data: { turbo_frame: "_top" }) { item.library.name }
                      if item.condition.present?
                        span(class: "text-green-600 text-xs bg-green-100 px-2 py-1 rounded") { item.condition }
                      end
                    end
                  end
                end
              end
            else
              div(class: "bg-white border border-blue-200 rounded-lg p-4 text-center") do
                p(class: "text-sm text-blue-700") { "Not in your library yet" }
              end
            end
          end

          # Action Buttons
          div(class: "px-6 pb-6") do
            # Library Selection Dropdown
            render Components::Shared::LibraryDropdownView.new(product: @product)

            # Refresh and Delete Product Buttons
            div(class: "mt-4 pt-4 border-t border-gray-300 flex gap-2") do
              # Refresh Data Button
              form(method: "post", action: refresh_product_path(@product), class: "inline") do
                input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
                button(
                  type: "submit",
                  class: "bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors text-sm"
                ) { "Refresh Data" }
              end

              # Delete Product Button
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
end
