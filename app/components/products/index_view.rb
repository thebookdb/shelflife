class Components::Products::IndexView < Components::Base
  def initialize(recent_products: [])
    @recent_products = recent_products
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      # Header Section
      div(class: "bg-white shadow-sm border-b border-gray-200") do
        div(class: "py-6") do
          div(class: "flex items-center justify-between mb-2") do
            h1(class: "text-2xl font-bold text-gray-800") { "Shelf Life" }
            div(class: "flex gap-3") do
              a(
                href: "/scanner",
                class: "bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors text-sm font-medium flex items-center gap-2"
              ) do
                span { "📱" }
                span { "Scan" }
              end
              a(
                href: "/scans",
                class: "text-blue-600 hover:text-blue-800 text-sm font-medium flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-blue-50 transition-colors"
              ) do
                span { "📋" }
                span { "My Scans" }
              end
            end
          end
          p(class: "text-gray-600") { "Your digital library" }
        end
      end

      # Content Area
      div(class: "py-6") do
        div(class: "max-w-5xl mx-auto") do
          if @recent_products.any?
            # Recent additions section
            div(class: "bg-white rounded-lg shadow-md p-6 mb-6") do
              h2(class: "text-xl font-semibold text-gray-800 mb-6") { "Recent Additions" }
              div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4") do
                @recent_products.each do |product|
                  a(href: "/#{product.gtin}", class: "group block") do
                    div(class: "flex items-center gap-4 p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-all hover:shadow-sm") do
                      div(class: "flex-shrink-0") do
                        if product.cover_image.attached?
                          img(
                            src: url_for(product.cover_image),
                            alt: product.title,
                            class: "w-16 h-16 object-cover rounded-lg border shadow-sm"
                          )
                        elsif product.cover_image_url.present?
                          img(
                            src: product.cover_image_url,
                            alt: product.title,
                            class: "w-16 h-16 object-cover rounded-lg border shadow-sm"
                          )
                        else
                          div(class: "w-16 h-16 bg-gray-200 rounded-lg border flex items-center justify-center") do
                            span(class: "text-2xl") { "📚" }
                          end
                        end
                      end
                      div(class: "flex-1 min-w-0") do
                        h3(class: "font-semibold text-gray-900 truncate group-hover:text-blue-600 transition-colors") { product.title }
                        if product.author.present?
                          p(class: "text-sm text-gray-600 truncate") { product.author }
                        end
                        if product.product_type.present?
                          span(class: "inline-block text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded-full mt-1") {
                            product.product_type.humanize
                          }
                        end
                      end
                    end
                  end
                end
              end
            end
          else
            # Welcome/empty state
            div(class: "bg-white rounded-lg shadow-md p-12 text-center") do
              div(class: "text-8xl mb-6") { "📚" }
              h2(class: "text-3xl font-bold text-gray-800 mb-4") { "Welcome to Shelf Life" }
              p(class: "text-lg text-gray-600 mb-8 max-w-2xl mx-auto") { "Start building your digital library by scanning books, DVDs, board games, and other items with barcodes" }

              a(
                href: "/scanner",
                class: "inline-flex items-center gap-3 bg-green-600 text-white px-8 py-4 rounded-lg hover:bg-green-700 transition-colors font-semibold text-lg shadow-lg hover:shadow-xl transform hover:scale-105"
              ) do
                span(class: "text-xl") { "📱" }
                span { "Start Scanning" }
              end

              div(class: "bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-6 text-left mt-8 max-w-lg mx-auto") do
                h3(class: "font-semibold text-blue-800 mb-4 text-lg") { "How it works:" }
                ul(class: "text-blue-700 space-y-3") do
                  li(class: "flex items-start gap-2") do
                    span(class: "text-green-600") { "✓" }
                    span { "Tap 'Start Scanning' above to open the camera" }
                  end
                  li(class: "flex items-start gap-2") do
                    span(class: "text-green-600") { "✓" }
                    span { "Point camera at product barcode" }
                  end
                  li(class: "flex items-start gap-2") do
                    span(class: "text-green-600") { "✓" }
                    span { "Product info appears instantly" }
                  end
                  li(class: "flex items-start gap-2") do
                    span(class: "text-green-600") { "✓" }
                    span { "Add to your library or wishlist" }
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
