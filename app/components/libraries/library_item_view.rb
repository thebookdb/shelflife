class Components::Libraries::LibraryItemView < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::URLFor
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::DateHelper

  def initialize(library_item:)
    @library_item = library_item
  end

  def view_template
    product = @library_item.product

    div(class: "bg-orange-50 rounded-lg shadow-md p-4 flex items-center gap-4 border-l-4 #{intent_border_class(@library_item)}", id: "library_item_#{@library_item.id}") do
      # Cover art section
      div(class: "flex-shrink-0") do
        if product.cover_image.attached?
          img(
            src: Rails.application.routes.url_helpers.rails_blob_path(product.cover_image, only_path: true),
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
        div(class: "flex flex-wrap items-center mt-2 text-sm gap-2") do
          # Intent badge
          if @library_item.want?
            span(class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800") do
              plain "Want"
            end
          else
            span(class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800") do
              plain "Have"
            end
          end

          span(class: "bg-gray-100 px-2 py-1 rounded text-gray-500") { (product.product_type || "other").humanize }
          span(class: "text-gray-500") { "GTIN: #{product.gtin}" }
          if @library_item.condition.present?
            span(class: "text-gray-500") { "Condition: #{@library_item.condition.name}" }
          end
          if @library_item.location.present?
            span(class: "text-gray-500") { "Location: #{@library_item.location}" }
          end
        end
        if @library_item.notes.present?
          p(class: "text-sm text-gray-600 mt-2") { @library_item.notes }
        end

        # Attribution
        if @library_item.added_by.present?
          p(class: "text-xs text-gray-400 mt-2") do
            plain "Added by #{@library_item.added_by.name || @library_item.added_by.email_address}"
            if @library_item.date_added
              plain " • #{time_ago_in_words(@library_item.date_added)} ago"
            end
          end
        end
      end

      # Actions section
      div(class: "flex flex-col items-end space-y-2") do
        a(href: library_item_path(@library_item), class: "text-blue-600 hover:text-blue-800 font-medium") { "View" }
        form_with url: "/library_items/#{@library_item.id}", method: :delete, class: "inline", local: true do |f|
          f.button "Remove",
            type: "submit",
            class: "text-red-600 hover:text-red-800",
            data: {confirm: "Remove from library?"}
        end
      end
    end
  end

  private

  def safe_image_url(attachment)
    # Try to get the image URL, fallback to placeholder for background jobs

    url_for(attachment) if attachment.attached?
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
