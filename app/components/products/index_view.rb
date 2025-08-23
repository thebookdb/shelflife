class Components::Products::IndexView < Components::Base
  def initialize(recent_products: [])
    @recent_products = recent_products
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      # Header Section
      div(class: "bg-white shadow-sm border-b border-gray-200") do
        div(class: "max-w-md mx-auto p-4") do
          div(class: "flex items-center justify-between mb-2") do
            h1(class: "text-xl font-bold text-gray-800") { "Shelf Life" }
            div(class: "flex gap-3") do
              a(
                href: "/scanner",
                class: "bg-green-600 text-white px-3 py-2 rounded-lg hover:bg-green-700 transition-colors text-sm font-medium flex items-center gap-1"
              ) do
                span { "📱" }
                span { "Scan" }
              end
              a(
                href: "/scans",
                class: "text-blue-600 hover:text-blue-800 text-sm font-medium flex items-center gap-1"
              ) do
                span { "📋" }
                span { "My Scans" }
              end
            end
          end
          p(class: "text-sm text-gray-600") { "Your digital library" }
        end
      end

      # Content Area
      div(class: "p-4") do
        div(class: "max-w-md mx-auto") do
          if @recent_products.any?
            # Recent additions section
            div(class: "bg-white rounded-lg shadow-md p-6 mb-6") do
              h2(class: "text-lg font-semibold text-gray-800 mb-4") { "Recent Additions" }
              div(class: "space-y-3") do
                @recent_products.each do |product|
                  a(href: "/#{product.ean}", class: "block") do
                    div(class: "flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors") do
                      div(class: "flex-shrink-0") do
                        if product.cover_image.attached?
                          img(
                            src: url_for(product.cover_image),
                            alt: product.title,
                            class: "w-12 h-12 object-cover rounded border"
                          )
                        elsif product.cover_image_url.present?
                          img(
                            src: product.cover_image_url,
                            alt: product.title,
                            class: "w-12 h-12 object-cover rounded border"
                          )
                        else
                          div(class: "w-12 h-12 bg-gray-200 rounded border flex items-center justify-center") do
                            span(class: "text-lg") { "📚" }
                          end
                        end
                      end
                      div(class: "flex-1 min-w-0") do
                        h3(class: "font-medium text-gray-900 truncate") { product.title }
                        if product.author.present?
                          p(class: "text-sm text-gray-600 truncate") { product.author }
                        end
                      end
                    end
                  end
                end
              end
            end
          else
            # Welcome/empty state
            div(class: "bg-white rounded-lg shadow-md p-6 text-center") do
              div(class: "text-6xl mb-4") { "📚" }
              h2(class: "text-xl font-semibold text-gray-800 mb-2") { "Welcome to Shelf Life" }
              p(class: "text-gray-600 mb-6") { "Start building your digital library by scanning books, DVDs, and board games" }

              a(
                href: "/scanner",
                class: "inline-flex items-center gap-2 bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 transition-colors font-medium"
              ) do
                span(class: "text-lg") { "📱" }
                span { "Start Scanning" }
              end

              div(class: "bg-blue-50 rounded-lg p-4 text-left mt-6") do
                h3(class: "font-semibold text-blue-800 mb-2") { "How it works:" }
                ul(class: "text-sm text-blue-700 space-y-1") do
                  li { "• Tap 'Start Scanning' above" }
                  li { "• Point camera at book barcode" }
                  li { "• Product info appears instantly" }
                  li { "• Add to your library or wishlist" }
                end
              end
            end
          end
        end
      end
    end
  end
end
