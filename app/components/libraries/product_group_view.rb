class Components::Libraries::ProductGroupView < Components::Base
  def initialize(product:, library_items:, library:)
    @product = product
    @library_items = library_items
    @library = library
  end

  def view_template
    @library_items.each do |item|
      render_item_card(item)
    end
  end

  private

  def render_item_card(item)
    div(class: "mb-4 bg-orange-50 rounded-lg shadow-md overflow-hidden border-l-4 #{intent_border_class(item)}") do
      # Product zone — links to product
      a(href: gtin_path(@product), class: "block m-4 mb-3 rounded-lg border border-slate-200 border-l-4 border-l-slate-400 bg-slate-50/50 hover:bg-slate-100/70 transition-colors") do
        div(class: "p-3 flex items-start gap-3") do
          div(class: "flex-shrink-0") do
            if @product.cover_image.attached?
              img(
                src: Rails.application.routes.url_helpers.rails_blob_path(@product.cover_image, only_path: true),
                alt: @product.safe_title,
                class: "w-14 h-20 object-cover rounded shadow-sm"
              )
            elsif @product.cover_image_url.present?
              img(
                src: @product.cover_image_url,
                alt: @product.safe_title,
                class: "w-14 h-20 object-cover rounded shadow-sm"
              )
            else
              div(class: "w-14 h-20 bg-gray-200 rounded flex items-center justify-center") do
                span(class: "text-2xl") { product_icon(@product.product_type) }
              end
            end
          end

          div(class: "flex-1 min-w-0") do
            p(class: "font-semibold text-gray-900 leading-tight hover:text-slate-600 transition-colors") do
              @product.safe_title
            end

            if @product.author.present?
              p(class: "text-sm text-gray-500 mt-0.5") { "by #{@product.author}" }
            end

            div(class: "flex flex-wrap items-center mt-1.5 text-xs text-gray-400 gap-2") do
              span(class: "bg-slate-100 text-slate-600 px-1.5 py-0.5 rounded") do
                (@product.product_type || "other").humanize
              end
              span(class: "font-mono") { @product.gtin }
            end
          end
        end
      end

      # Your copy zone — links to library item
      a(href: library_item_path(item), class: "block px-4 pb-4 hover:bg-orange-100/50 transition-colors rounded-b-lg") do
        p(class: "text-sm text-gray-800") do
          plain(item.have? ? "Added to " : "Wishlisted in ")
          span(class: "font-semibold") { @library.name }
          if item.date_added.present?
            plain " on #{item.date_added.strftime("%-d %B %Y")}"
          end
        end

        details = []
        details << "Condition: #{item.condition.name}" if item.condition.present?
        details << item.item_status.name if item.item_status.present?
        details << item.location if item.location.present?

        if details.any?
          p(class: "text-xs text-gray-500 mt-1") { details.join(" · ") }
        end

        if item.notes.present?
          p(class: "text-xs text-gray-400 mt-1.5 italic") { item.notes }
        end
      end
    end
  end

  private

end
