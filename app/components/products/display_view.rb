class Components::Products::DisplayView < Components::Base
  def initialize(product:, libraries: [])
    @product = product
    @libraries = libraries
  end

  def view_template
    turbo_frame(id: "product-display", data: { product_id: @product.id }) do
      div(class: "bg-white rounded-lg shadow-md overflow-hidden") do
        # Product Header with Cover
        div(class: "p-6 pb-4") do
          div(class: "flex gap-4") do
            # Cover Image
            div(class: "flex-shrink-0") do
              if @product.cover_image.attached?
                img(
                  src: Rails.application.routes.url_helpers.rails_blob_path(@product.cover_image, only_path: true),
                  alt: @product.title,
                  class: "w-16 h-24 object-cover rounded shadow-sm"
                )
              elsif @product.cover_image_url.present?
                # Fallback to URL during transition period
                img(
                  src: @product.cover_image_url,
                  alt: @product.title,
                  class: "w-16 h-24 object-cover rounded shadow-sm"
                )
              else
                div(class: "w-16 h-24 bg-gray-200 rounded flex items-center justify-center") do
                  span(class: "text-2xl") { product_icon }
                end
              end
            end

            # Product Info
            div(class: "flex-1 min-w-0") do
              h2(class: "text-lg font-semibold text-gray-900 leading-tight mb-1") { @product.title }

              if @product.subtitle.present?
                p(class: "text-sm text-gray-600 mb-1") { @product.subtitle }
              end

              if @product.author.present?
                p(class: "text-sm text-gray-700 mb-1") { "by #{@product.author}" }
              end

              if @product.publisher.present?
                p(class: "text-xs text-gray-500") { @product.publisher }
              end

              # GTIN badge
              div(class: "mt-2") do
                span(class: "inline-block bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded font-mono") do
                  @product.gtin
                end
              end
            end
          end
        end

        # Description (if available)
        if @product.description.present?
          div(class: "px-6 pb-4") do
            div(class: "bg-gray-50 rounded-lg p-3") do
              p(class: "text-sm text-gray-700 leading-relaxed") do
                truncated_description
              end
            end
          end
        end

        # Product Details
        if has_product_details?
          div(class: "px-6 pb-4") do
            div(class: "grid grid-cols-2 gap-4 text-sm") do
              if @product.pages.present?
                div do
                  span(class: "text-gray-500") { "Pages: " }
                  span(class: "font-medium") { @product.pages }
                end
              end

              if @product.publication_date.present?
                div do
                  span(class: "text-gray-500") { "Published: " }
                  span(class: "font-medium") { @product.publication_date.year }
                end
              end

              if @product.genre.present?
                div do
                  span(class: "text-gray-500") { "Genre: " }
                  span(class: "font-medium") { @product.genre }
                end
              end

              div do
                span(class: "text-gray-500") { "Type: " }
                span(class: "font-medium capitalize") { @product.product_type.humanize }
              end
            end
          end
        end

        # Current Library Status
        div(class: "px-6 pb-4") do
          current_library_items = @product.library_items.includes(:library)

          if current_library_items.any?
            div(class: "bg-green-50 border border-green-200 rounded-lg p-3") do
              h3(class: "text-sm font-semibold text-green-800 mb-2") { "In Your Libraries:" }
              div(class: "space-y-1") do
                current_library_items.each do |item|
                  div(class: "flex justify-between items-center text-sm") do
                    span(class: "text-green-700") { item.library.name }
                    if item.condition.present?
                      span(class: "text-green-600 text-xs") { "(#{item.condition})" }
                    end
                  end
                end
              end
            end
          else
            div(class: "bg-blue-50 border border-blue-200 rounded-lg p-3 text-center") do
              p(class: "text-sm text-blue-700") { "Not in your library yet" }
            end
          end
        end

        # Action Buttons
        div(class: "px-6 pb-6") do
          div(class: "flex flex-col gap-3") do
            # Add to Library/Wishlist buttons
            unless @product.library_items.any? { |item| !item.library.wishlist? }
              # Show "Add to Library" options
              div(class: "grid grid-cols-2 gap-3") do
                button(
                  type: "button",
                  data_action: "click->barcode-scanner#addToLibrary",
                  data_library_name: "Home",
                  class: "bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors font-medium text-sm"
                ) { "📚 Add to Home" }

                button(
                  type: "button",
                  data_action: "click->barcode-scanner#addToLibrary",
                  data_library_name: "Work",
                  class: "bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors font-medium text-sm"
                ) { "🏢 Add to Work" }
              end
            end

            # Wishlist button (always available)
            unless @product.library_items.any? { |item| item.library.wishlist? }
              button(
                type: "button",
                data_action: "click->barcode-scanner#addToWishlist",
                class: "bg-purple-600 text-white py-2 px-4 rounded-lg hover:bg-purple-700 transition-colors font-medium text-sm"
              ) { "⭐ Add to Wishlist" }
            end

            # Continue Scanning button
            button(
              type: "button",
              data_action: "click->barcode-scanner#continueScan",
              class: "bg-gray-600 text-white py-2 px-4 rounded-lg hover:bg-gray-700 transition-colors font-medium text-sm"
            ) { "📱 Scan Another" }
          end
        end

        # Data Enrichment Status
        if !@product.enriched?
          div(class: "px-6 pb-4") do
            div(class: "bg-yellow-50 border border-yellow-200 rounded-lg p-3 text-center") do
              div(class: "animate-pulse flex items-center justify-center gap-2") do
                div(class: "w-3 h-3 bg-yellow-500 rounded-full")
                span(class: "text-sm text-yellow-700") { "Fetching additional details..." }
              end
            end
          end
        end
      end
    end
  end

  private

  def product_icon
    case @product.product_type
    when "book" then "📚"
    when "dvd" then "💿"
    when "board_game" then "🎲"
    else "📦"
    end
  end

  def truncated_description
    return @product.description if @product.description.length <= 150

    "#{@product.description[0..147]}..."
  end

  def has_product_details?
    @product.pages.present? ||
    @product.publication_date.present? ||
    @product.genre.present?
  end
end
