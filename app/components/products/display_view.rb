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
      # The actual content that gets replaced by broadcasts
      turbo_frame(id: "product-display") do
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
                    span(class: "font-medium capitalize") { (@product.product_type || "other").humanize }
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
                        a(href: library_path(item.library), class: "text-green-700 hover:text-green-900 hover:underline font-medium", data: { turbo_frame: "_top" }) { item.library.name }
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
              # Library Selection Dropdown
              render Components::Shared::LibraryDropdownView.new(product: @product)

              # Delete Product Button
              div(class: "mt-4 pt-4 border-t border-gray-200") do
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

            # Data Enrichment Status
            if !@product.enriched?
              div(class: "px-6 pb-4") do
                rate_limit_status = Rails.cache.read("tbdb_rate_limit_status")

                if rate_limit_status&.dig(:limited)
                  # Show rate limit message
                  div(class: "bg-orange-50 border border-orange-200 rounded-lg p-3 text-center") do
                    div(class: "flex items-center justify-center gap-2") do
                      span(class: "text-sm text-orange-700") do
                        plain "📚 API rate limit reached. Data fetching will resume automatically at "
                        strong { rate_limit_status[:reset_time].strftime("%I:%M %p") }
                        plain "."
                      end
                    end
                  end
                elsif @product.enrichment_failed?
                  # Show enrichment error message
                  div(class: "bg-red-50 border border-red-200 rounded-lg p-3 text-center") do
                    span(class: "text-sm text-red-700") do
                      plain "⚠️ Failed to fetch additional details. Jobs will retry automatically."
                    end
                  end
                else
                  # Show normal fetching message
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
      end
    end
  end

  private

  def product_icon
    case @product.product_type
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
