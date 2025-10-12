class Components::Products::DisplayDataView < Components::Base
  def initialize(product:, libraries: [])
    @product = product
    @libraries = libraries.presence || Library.all
  end

  def view_template
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
          h2(class: "text-lg font-semibold text-gray-900 leading-tight mb-2") { @product.title }

          if @product.subtitle.present?
            p(class: "text-sm text-gray-600 mb-2") { @product.subtitle }
          end

          # Enhanced Author/Contributors Display
          if @product.author.present?
            div(class: "mb-2") do
              span(class: "text-sm text-gray-500") { "by " }
              span(class: "text-sm font-medium text-gray-800") { @product.author }
            end
          end

          # Publisher and Publication Info
          div(class: "flex flex-wrap gap-3 text-xs text-gray-500 mb-2") do
            if @product.publisher.present?
              span { @product.publisher }
            end

            if @product.publication_date.present?
              span { "• #{@product.publication_date.year}" }
            end
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
            span(class: "font-medium capitalize") { (@product.product_type || "other").humanize }
          end
        end
      end
    end

    # Data Enrichment Status (no forms, just status)
    if !@product.enriched?
      div(class: "px-6 pb-4") do
        rate_limit_status = Rails.cache.read("tbdb_rate_limit_status")
        enrichment_status = @product.tbdb_data&.dig("status")

        if enrichment_status == "authentication_failed"
          # Show authentication error with reconnect link
          div(class: "bg-red-50 border border-red-200 rounded-lg p-3") do
            div(class: "flex items-start justify-between gap-3") do
              div(class: "flex-1") do
                div(class: "text-sm font-medium text-red-800") { "❌ TBDB Connection Required" }
                div(class: "text-xs text-red-600 mt-1") do
                  plain @product.tbdb_data&.dig("message") || "Authentication failed. Please reconnect to TBDB."
                end
              end
              a(
                href: "/profile",
                class: "inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded text-white bg-red-600 hover:bg-red-700"
              ) { "View Connection" }
            end
          end
        elsif enrichment_status == "quota_exhausted"
          # Show quota exhausted message with retry time
          retry_at = @product.tbdb_data&.dig("retry_at")
          div(class: "bg-purple-50 border border-purple-200 rounded-lg p-3 text-center") do
            div(class: "text-sm text-purple-700") do
              plain "📊 Daily API quota exhausted. "
              if retry_at
                plain "Will retry at #{Time.parse(retry_at).strftime('%I:%M %p')}."
              else
                plain "Will retry automatically when quota resets."
              end
            end
          end
        elsif enrichment_status == "rate_limited" || rate_limit_status&.dig(:limited)
          # Show rate limit message
          retry_at = @product.tbdb_data&.dig("retry_at") || rate_limit_status&.dig(:reset_time)
          div(class: "bg-orange-50 border border-orange-200 rounded-lg p-3 text-center") do
            div(class: "flex items-center justify-center gap-2") do
              span(class: "text-sm text-orange-700") do
                plain "📚 API rate limit reached. Data fetching will resume "
                if retry_at
                  if retry_at.is_a?(String)
                    plain "at #{Time.parse(retry_at).strftime('%I:%M %p')}"
                  else
                    plain "at #{retry_at.strftime('%I:%M %p')}"
                  end
                else
                  plain "automatically"
                end
                plain "."
              end
            end
          end
        elsif @product.enrichment_failed?
          # Show generic enrichment error message
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
