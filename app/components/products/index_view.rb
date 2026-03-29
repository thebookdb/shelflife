class Components::Products::IndexView < Components::Base
  def initialize(products: [], show_onboarding: false)
    @products = products
    @show_onboarding = show_onboarding
  end

  def view_template
    render Components::Shared::OnboardingModalView.new if @show_onboarding

    div(class: "min-h-screen bg-gray-50 pt-16") do
      div(class: "py-8 max-w-6xl mx-auto px-4") do
        h1(class: "text-3xl font-bold text-gray-900 mb-6") { "Items" }

        if @products.any?
          div(class: "bg-white rounded-xl shadow-sm border border-gray-100 p-6") do
            div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4") do
              @products.each do |product|
                library_item = product.library_items.max_by(&:created_at)
                card_href = library_item ? library_item_path(library_item) : "/#{product.gtin}"

                a(href: card_href, class: "group block") do
                  div(class: "flex items-center gap-4 p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-all hover:shadow-sm border-l-4 #{intent_border_class(library_item)}") do
                    div(class: "flex-shrink-0") do
                      if product.cover_image.attached?
                        img(src: url_for(product.cover_image), alt: product.title, class: "w-16 h-20 object-cover rounded border shadow-sm")
                      elsif product.cover_image_url.present?
                        img(src: product.cover_image_url, alt: product.title, class: "w-16 h-20 object-cover rounded border shadow-sm")
                      else
                        div(class: "w-16 h-20 bg-gray-200 rounded border flex items-center justify-center") do
                          span(class: "text-2xl") { "📚" }
                        end
                      end
                    end
                    div(class: "flex-1 min-w-0") do
                      p(class: "font-semibold text-gray-900 truncate group-hover:text-primary-600 transition-colors") { product.title }
                      if product.author.present?
                        p(class: "text-sm text-gray-500 truncate mt-0.5") { product.author }
                      end
                      if product.product_type.present?
                        span(class: "inline-block text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full mt-1") { product.product_type.humanize }
                      end
                    end
                  end
                end
              end
            end
          end
        else
          div(class: "bg-white rounded-xl shadow-sm border border-gray-100 p-12 text-center") do
            div(class: "text-6xl mb-4") { "📚" }
            p(class: "text-lg text-gray-400 italic") { "No items yet — scan something!" }
          end
        end
      end
    end
  end
end
