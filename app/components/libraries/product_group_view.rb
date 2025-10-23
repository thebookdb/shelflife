class Components::Libraries::ProductGroupView < Components::Base
  def initialize(product:, library_items:)
    @product = product
    @library_items = library_items
  end

  def view_template
    div(class: "bg-white rounded-lg shadow-md overflow-hidden mb-4") do
      # Product header with cover and basic info
      div(class: "p-4 flex items-start gap-4 border-b border-gray-200") do
        # Cover art
        div(class: "flex-shrink-0") do
          if @product.cover_image.attached?
            img(
              src: Rails.application.routes.url_helpers.rails_blob_path(@product.cover_image, only_path: true),
              alt: @product.safe_title,
              class: "w-20 h-28 object-cover rounded shadow-sm"
            )
          elsif @product.cover_image_url.present?
            img(
              src: @product.cover_image_url,
              alt: @product.safe_title,
              class: "w-20 h-28 object-cover rounded shadow-sm"
            )
          else
            div(class: "w-20 h-28 bg-gray-200 rounded flex items-center justify-center") do
              span(class: "text-3xl") { product_icon(@product.product_type) }
            end
          end
        end

        # Product details
        div(class: "flex-1") do
          a(href: "/#{@product.gtin}", class: "text-xl font-semibold text-gray-900 hover:text-blue-600 transition-colors") do
            @product.safe_title
          end

          if @product.author.present?
            p(class: "text-gray-600 mt-1") { "by #{@product.author}" }
          end

          div(class: "flex flex-wrap items-center mt-2 text-sm text-gray-500 gap-2") do
            span(class: "bg-gray-100 px-2 py-1 rounded") { (@product.product_type || "other").humanize }
            span { "GTIN: #{@product.gtin}" }
          end
        end

        # Copy count badge
        div(class: "flex-shrink-0") do
          div(class: "bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-semibold") do
            plain "#{@library_items.count} "
            plain @library_items.count == 1 ? "copy" : "copies"
          end
        end
      end

      # List of copies
      div(class: "bg-gray-50") do
        @library_items.each_with_index do |item, index|
          div(class: "px-4 py-3 #{index > 0 ? 'border-t border-gray-200' : ''}") do
            div(class: "flex items-center justify-between") do
              # Copy info
              div(class: "flex-1") do
                div(class: "flex items-center gap-3 text-sm") do
                  span(class: "font-medium text-gray-700") do
                    plain "Copy "
                    plain (index + 1).to_s
                  end

                  if item.item_status&.name.present?
                    status_color = status_badge_color(item.item_status.name)
                    span(class: "px-2 py-1 rounded text-xs font-medium #{status_color}") do
                      item.item_status.name
                    end
                  end

                  if item.condition.present?
                    span(class: "text-gray-600") { "Condition: #{item.condition}" }
                  end

                  if item.location.present?
                    span(class: "text-gray-600") { "📍 #{item.location}" }
                  end
                end

                if item.notes.present?
                  p(class: "text-sm text-gray-600 mt-1") { item.notes }
                end
              end

              # Actions
              div(class: "flex items-center gap-2") do
                a(
                  href: library_item_path(item),
                  class: "text-blue-600 hover:text-blue-800 font-medium text-sm"
                ) { "Manage" }
              end
            end
          end
        end
      end
    end
  end

  private

  def product_icon(product_type)
    case product_type
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

  def status_badge_color(status_name)
    case status_name
    when "Available"
      "bg-green-100 text-green-800"
    when "Checked Out"
      "bg-yellow-100 text-yellow-800"
    when "Missing"
      "bg-red-100 text-red-800"
    when "Damaged"
      "bg-orange-100 text-orange-800"
    when "In Repair"
      "bg-purple-100 text-purple-800"
    when "Retired"
      "bg-gray-100 text-gray-800"
    else
      "bg-blue-100 text-blue-800"
    end
  end
end
