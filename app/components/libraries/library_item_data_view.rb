class Components::Libraries::LibraryItemDataView < Components::Base
  def initialize(library_item:)
    @library_item = library_item
  end

  def view_template
    product = @library_item.product

    div(class: "bg-white rounded-lg shadow-md p-4 flex items-center gap-4", id: "library_item_#{@library_item.id}") do
      # Cover art section
      div(class: "flex-shrink-0") do
        if product.cover_image.attached?
          img(
            src: safe_image_url(product.cover_image),
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
          span(class: "bg-gray-100 px-2 py-1 rounded") { (product.product_type || "other").humanize }
          span { "GTIN: #{product.gtin}" }
          if @library_item.condition.present?
            span { "Condition: #{@library_item.condition}" }
          end
          if @library_item.location.present?
            span { "Location: #{@library_item.location}" }
          end
        end
        if @library_item.notes.present?
          p(class: "text-sm text-gray-600 mt-2") { @library_item.notes }
        end
      end

      # Actions section - data only, no forms
      div(class: "flex flex-col items-end space-y-2") do
        a(href: "/#{product.gtin}", class: "text-blue-600 hover:text-blue-800 font-medium") { "View" }
      end
    end
  end

  private

  def safe_image_url(attachment)
    # Try to get the image URL, fallback to placeholder for background jobs

    Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true) if attachment.attached?
  rescue
    "/placeholder-image.jpg" # fallback for background jobs
  end

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
end
