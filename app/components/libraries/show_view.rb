class Components::Libraries::ShowView < Components::Base
  # include Rails.application.routes.url_helpers
  include Pagy::Frontend
  include ActionView::Helpers::FormTagHelper

  def initialize(library:, library_items:, pagy: nil)
    @library = library
    @library_items = library_items
    @pagy = pagy
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      render Components::Shared::NavigationView.new

      div(class: "pt-20 px-4") do
        div(class: "max-w-4xl mx-auto") do
          div(class: "mb-8") do
            div(class: "flex items-center justify-between") do
              div do
                h1(class: "text-3xl font-bold text-gray-900") { @library.name }
                if @library.description.present?
                  p(class: "text-gray-600 mt-2") { @library.description }
                end
              end

              a(href: edit_library_path(@library), class: "bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors") { "Edit Library" }
            end
          end

          if @library_items.any?
            div(class: "grid gap-4") do
              @library_items.each do |library_item|
                render_library_item(library_item)
              end
            end

            # Pagination
            if @pagy && @pagy.pages > 1
              div(class: "mt-8 flex justify-center") do
                unsafe_raw pagy_nav(@pagy)
              end
            end
          else
            div(class: "bg-white rounded-lg shadow-md p-8 text-center") do
              div(class: "text-6xl mb-4") { "📚" }
              h2(class: "text-xl font-semibold text-gray-800 mb-2") { "#{@library.name} is empty" }
              p(class: "text-gray-600 mb-4") { "No items have been added to this library yet" }
              a(href: root_path, class: "bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors") do
                "Start Scanning"
              end
            end
          end
        end
      end
    end
  end

  private

  def render_library_item(library_item)
    product = library_item.product

    div(class: "bg-white rounded-lg shadow-md p-4 flex items-center gap-4") do
      # Cover art section
      div(class: "flex-shrink-0") do
        if product.cover_image.attached?
          img(
            src: helpers.url_for(product.cover_image),
            alt: product.safe_title,
            class: "w-16 h-20 object-cover rounded shadow-sm"
          )
        elsif product.cover_image_url.present?
          img(
            src: product.cover_image_url,
            alt: product.safe_title,
            class: "w-16 h-20 object-cover rounded shadow-sm"
          )
        else
          div(class: "w-16 h-20 bg-gray-200 rounded flex items-center justify-center") do
            span(class: "text-2xl") { product_icon(product.product_type) }
          end
        end
      end

      # Product details section
      div(class: "flex-1") do
        h3(class: "font-semibold text-gray-900") { product.safe_title }
        if product.author.present?
          p(class: "text-gray-600") { "by #{product.author}" }
        end
        div(class: "flex flex-wrap items-center mt-2 text-sm text-gray-500 gap-2") do
          span(class: "bg-gray-100 px-2 py-1 rounded") { product.product_type.humanize }
          span { "GTIN: #{product.gtin}" }
          if library_item.condition.present?
            span { "Condition: #{library_item.condition}" }
          end
          if library_item.location.present?
            span { "Location: #{library_item.location}" }
          end
        end
        if library_item.notes.present?
          p(class: "text-sm text-gray-600 mt-2") { library_item.notes }
        end
      end

      # Actions section
      div(class: "flex flex-col items-end space-y-2") do
        a(href: "/#{product.gtin}", class: "text-blue-600 hover:text-blue-800 font-medium") { "View" }
        form(method: "post", action: "/library_items/#{library_item.id}", class: "inline") do
          input(type: "hidden", name: "_method", value: "delete")
          input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
          button(
            type: "submit",
            class: "text-red-600 hover:text-red-800",
            **{ "data-confirm": "Remove from library?" }
          ) { "Remove" }
        end
      end
    end
  end

  def product_icon(product_type)
    case product_type
    when "book" then "📚"
    when "dvd" then "💿"
    when "board_game" then "🎲"
    else "📦"
    end
  end
end
