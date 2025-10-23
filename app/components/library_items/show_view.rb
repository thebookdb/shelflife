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
              a(href: libraries_path, class: "hover:text-blue-600") { "Libraries" }
              plain " / "
              a(href: library_path(@library), class: "hover:text-blue-600") { @library.name }
              plain " / "
              span(class: "text-gray-900") { "Item Details" }
            end

            h1(class: "text-3xl font-bold text-gray-900") { "Library Item" }
          end

          div(class: "bg-white rounded-lg shadow-md overflow-hidden") do
            # Product information section
            div(class: "border-b border-gray-200 p-6") do
              h2(class: "text-lg font-semibold text-gray-800 mb-4") { "Product Information" }

              div(class: "flex gap-6") do
                # Cover image
                div(class: "flex-shrink-0") do
                  if @product.cover_image.attached?
                    img(
                      src: Rails.application.routes.url_helpers.rails_blob_path(@product.cover_image, only_path: true),
                      alt: @product.safe_title,
                      class: "w-32 h-44 object-cover rounded shadow-sm"
                    )
                  elsif @product.cover_image_url.present?
                    img(
                      src: @product.cover_image_url,
                      alt: @product.safe_title,
                      class: "w-32 h-44 object-cover rounded shadow-sm"
                    )
                  else
                    div(class: "w-32 h-44 bg-gray-200 rounded flex items-center justify-center") do
                      span(class: "text-4xl") { product_icon(@product.product_type) }
                    end
                  end
                end

                # Product details
                div(class: "flex-1") do
                  a(href: "/#{@product.gtin}", class: "text-xl font-semibold text-blue-600 hover:text-blue-800") do
                    @product.safe_title
                  end

                  if @product.author.present?
                    p(class: "text-gray-700 mt-2") { "by #{@product.author}" }
                  end

                  div(class: "mt-4 space-y-1 text-sm text-gray-600") do
                    div { plain "Type: "; span(class: "font-medium") { (@product.product_type || "other").humanize } }
                    div { plain "GTIN: "; span(class: "font-medium") { @product.gtin } }
                  end
                end
              end
            end

            # Item-specific details section
            div(class: "p-6") do
              h2(class: "text-lg font-semibold text-gray-800 mb-4") { "Item Details" }

              div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
                detail_item("Library", @library.name)
                detail_item("Status", @library_item.item_status&.name || "Not set")
                detail_item("Condition", @library_item.condition || "Not recorded")
                detail_item("Location", @library_item.location || "Not specified")
                detail_item("Ownership", @library_item.ownership_status&.name || "Not set")
                detail_item("Copy ID", @library_item.copy_identifier) if @library_item.copy_identifier.present?
              end

              if @library_item.condition_notes.present?
                div(class: "mt-4") do
                  h3(class: "text-sm font-semibold text-gray-700 mb-1") { "Condition Notes" }
                  p(class: "text-gray-600 text-sm") { @library_item.condition_notes }
                end
              end

              if @library_item.notes.present?
                div(class: "mt-4") do
                  h3(class: "text-sm font-semibold text-gray-700 mb-1") { "Notes" }
                  p(class: "text-gray-600 text-sm") { @library_item.notes }
                end
              end
            end

            # Acquisition details section
            if has_acquisition_details?
              div(class: "border-t border-gray-200 p-6") do
                h2(class: "text-lg font-semibold text-gray-800 mb-4") { "Acquisition Details" }

                div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
                  detail_item("Date Acquired", @library_item.acquisition_date&.strftime("%B %d, %Y"))
                  detail_item("Source", @library_item.acquisition_source&.name)
                  detail_item("Purchase Price", format_currency(@library_item.acquisition_price))
                  detail_item("Original Retail", format_currency(@library_item.original_retail_price))
                  detail_item("Replacement Cost", format_currency(@library_item.replacement_cost))
                  detail_item("Current Value", format_currency(@library_item.current_market_value))
                end
              end
            end

            # Circulation details
            if @library_item.lent_to.present?
              div(class: "border-t border-gray-200 p-6 bg-yellow-50") do
                h2(class: "text-lg font-semibold text-gray-800 mb-4") { "Circulation Status" }

                div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
                  detail_item("Lent To", @library_item.lent_to)
                  detail_item("Due Date", @library_item.due_date&.strftime("%B %d, %Y"))

                  if @library_item.overdue?
                    div(class: "col-span-2") do
                      div(class: "bg-red-100 border border-red-300 text-red-800 px-4 py-2 rounded") do
                        plain "⚠️ This item is overdue!"
                      end
                    end
                  end
                end
              end
            end

            # Tags
            if @library_item.tags&.any?
              div(class: "border-t border-gray-200 p-6") do
                h2(class: "text-lg font-semibold text-gray-800 mb-3") { "Tags" }
                div(class: "flex flex-wrap gap-2") do
                  @library_item.tags.each do |tag|
                    span(class: "bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm") { tag }
                  end
                end
              end
            end

            # Action buttons
            div(class: "border-t border-gray-200 p-6 bg-gray-50") do
              div(class: "flex gap-3") do
                a(
                  href: edit_library_item_path(@library_item),
                  class: "bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
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

    div(class: "text-sm") do
      dt(class: "text-gray-600 font-medium") { label }
      dd(class: "text-gray-900 mt-1") { value }
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
    "$#{'%.2f' % amount}"
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
