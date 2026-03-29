class Components::LibraryItems::ShowView < Components::Base
  def initialize(library_item:)
    @library_item = library_item
    @product = library_item.product
    @library = library_item.library
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      render Components::Shared::NavigationView.new

      div(class: "pt-20 px-4") do
        div(class: "max-w-4xl mx-auto") do
          # Header with breadcrumb
          div(class: "mb-6") do
            nav(class: "text-sm text-gray-600 mb-4") do
              a(href: libraries_path, class: "hover:text-orange-600") { "Libraries" }
              plain " / "
              a(href: library_path(@library), class: "hover:text-orange-600") { @library.name }
              plain " / "
              span(class: "text-gray-900 font-medium") { @product.safe_title }
            end

            h1(class: "text-3xl font-bold text-gray-900") { @library_item.have? ? "Your Copy" : "On Your Wishlist" }
          end

          div(class: "bg-orange-50 rounded-lg shadow-md overflow-hidden border-l-4 #{intent_border_class(@library_item)}") do
            div(class: "m-4 mb-3 rounded-lg border border-slate-200 border-l-4 border-l-slate-400 bg-slate-50/50") do
              div(class: "p-4 flex gap-4") do
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

                div(class: "flex-1 min-w-0") do
                  a(href: "/#{@product.gtin}", class: "text-lg font-semibold text-slate-700 hover:text-slate-900 transition-colors") do
                    @product.safe_title
                  end

                  if @product.author.present?
                    p(class: "text-sm text-gray-500 mt-1") { "by #{@product.author}" }
                  end

                  div(class: "flex flex-wrap items-center mt-2 text-xs text-gray-400 gap-2") do
                    span(class: "bg-slate-100 text-slate-600 px-1.5 py-0.5 rounded") do
                      (@product.product_type || "other").humanize
                    end
                    span(class: "font-mono") { @product.gtin }
                  end
                end
              end
            end

            div(class: "px-6 pb-4 pt-2") do
              h2(class: "text-lg font-semibold text-orange-700 mb-4") { "Item Details" }

              div(class: "grid grid-cols-1 md:grid-cols-2 gap-3") do
                detail_item("Library", @library.name)
                detail_item("Status", @library_item.item_status&.name || "Not set")
                detail_item("Condition", @library_item.condition || "Not recorded")
                detail_item("Location", @library_item.location || "Not specified")
                detail_item("Ownership", @library_item.ownership_status&.name || "Not set")
                detail_item("Copy ID", @library_item.copy_identifier) if @library_item.copy_identifier.present?
              end

              if @library_item.condition_notes.present?
                div(class: "mt-4 bg-orange-100/60 rounded-lg p-3") do
                  h3(class: "text-sm font-semibold text-orange-700 mb-1") { "Condition Notes" }
                  p(class: "text-gray-700 text-sm") { @library_item.condition_notes }
                end
              end

              if @library_item.notes.present?
                div(class: "mt-4 bg-orange-100/60 rounded-lg p-3") do
                  h3(class: "text-sm font-semibold text-orange-700 mb-1") { "Notes" }
                  p(class: "text-gray-700 text-sm") { @library_item.notes }
                end
              end
            end

            if has_acquisition_details?
              div(class: "border-t border-orange-200 px-6 py-4") do
                h2(class: "text-lg font-semibold text-orange-700 mb-4") { "Acquisition Details" }

                div(class: "grid grid-cols-1 md:grid-cols-2 gap-3") do
                  detail_item("Date Acquired", @library_item.acquisition_date&.strftime("%B %d, %Y"))
                  detail_item("Source", @library_item.acquisition_source&.name)
                  detail_item("Purchase Price", format_currency(@library_item.acquisition_price))
                  detail_item("Original Retail", format_currency(@library_item.original_retail_price))
                  detail_item("Replacement Cost", format_currency(@library_item.replacement_cost))
                  detail_item("Current Value", format_currency(@library_item.current_market_value))
                end
              end
            end

            if @library_item.tags&.any?
              div(class: "border-t border-orange-200 px-6 py-4") do
                h2(class: "text-lg font-semibold text-orange-700 mb-3") { "Tags" }
                div(class: "flex flex-wrap gap-2") do
                  @library_item.tags.each do |tag|
                    span(class: "bg-orange-100 text-orange-800 px-3 py-1 rounded-full text-sm") { tag }
                  end
                end
              end
            end

            div(class: "border-t border-orange-200 p-6 bg-orange-100/40") do
              div(class: "flex gap-3") do
                a(
                  href: edit_library_item_path(@library_item),
                  class: "#{@library_item.have? ? "bg-orange-600 hover:bg-orange-700" : "bg-slate-600 hover:bg-slate-700"} text-white px-6 py-2 rounded-lg transition-colors"
                ) { "Edit Item Details" }

                a(
                  href: library_path(@library),
                  class: "bg-gray-600 text-white px-6 py-2 rounded-lg hover:bg-gray-700 transition-colors"
                ) { "Back to Library" }
              end
            end
          end
        end
      end
    end
  end

  private

  def detail_item(label, value)
    return unless value.present?

    div(class: "bg-orange-100/60 rounded-lg px-3 py-2 text-sm") do
      dt(class: "text-orange-700 font-medium text-xs") { label }
      dd(class: "text-gray-900 mt-0.5") { value }
    end
  end

  def has_acquisition_details?
    @library_item.acquisition_date.present? ||
      @library_item.acquisition_source.present? ||
      @library_item.acquisition_price.present? ||
      @library_item.original_retail_price.present? ||
      @library_item.replacement_cost.present? ||
      @library_item.current_market_value.present?
  end

  def format_currency(amount)
    return nil unless amount.present?
    "$#{"%.2f" % amount}"
  end

end
