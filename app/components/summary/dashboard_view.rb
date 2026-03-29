class Components::Summary::DashboardView < Components::Base
  def initialize(libraries_with_items: [], show_onboarding: false)
    @libraries_with_items = libraries_with_items
    @show_onboarding = show_onboarding
  end

  def view_template
    render Components::Shared::OnboardingModalView.new if @show_onboarding

    div(class: "min-h-screen bg-gray-50 pt-16") do
      div(class: "py-8 max-w-6xl mx-auto px-4") do
        h1(class: "text-3xl font-bold text-gray-900 mb-6") { "Dashboard" }
        if @libraries_with_items.empty?
          render_empty_state
        else
          @libraries_with_items.each do |entry|
            render_library_section(entry[:library], entry[:items])
          end
        end
      end
    end
  end

  private

  def render_library_section(library, items)
    div(class: "mb-6 bg-white rounded-xl shadow-sm border border-gray-100 p-6") do
      div(class: "flex items-baseline gap-3 mb-4") do
        a(href: library_path(library), class: "hover:text-primary-600 transition-colors") do
          h2(class: "text-xl font-bold text-gray-900") { library.name }
        end
        if library.description.present?
          span(class: "text-sm text-gray-400") { library.description }
        end
      end

      if items.any?
        div(class: "flex gap-4 overflow-x-auto pb-2") do
          items.each { |item| render_book_card(item.product) }
        end
      else
        div(class: "text-gray-400 text-base italic py-4") { "No items yet — scan something!" }
      end

      render_recommendations
    end
  end

  def render_book_card(product)
    a(href: "/#{product.gtin}", class: "flex-shrink-0 group w-28") do
      div(class: "w-28 h-40 rounded-lg overflow-hidden shadow-md mb-2 bg-gray-200 border border-gray-100 group-hover:shadow-lg transition-shadow") do
        if product.cover_image.attached?
          img(src: url_for(product.cover_image), alt: product.title, class: "w-full h-full object-cover")
        elsif product.cover_image_url.present?
          img(src: product.cover_image_url, alt: product.title, class: "w-full h-full object-cover")
        else
          div(class: "w-full h-full flex items-center justify-center") do
            span(class: "text-4xl") { "📚" }
          end
        end
      end
      p(class: "text-xs font-semibold text-gray-800 leading-tight line-clamp-2 group-hover:text-primary-600 transition-colors") { product.title }
      if product.author.present?
        p(class: "text-xs text-gray-400 mt-0.5 truncate") { product.author }
      end
    end
  end

  def render_recommendations
    div(class: "mt-5 flex gap-3") do
      div(class: "flex items-center gap-2 px-4 py-3 rounded-xl bg-indigo-50 border border-indigo-100 text-indigo-400 text-sm font-medium flex-1 justify-center opacity-60 cursor-not-allowed select-none") do
        span { "🚀" }
        span { "Explore" }
      end

      div(class: "flex-[2] rounded-xl bg-purple-50 border border-purple-100 px-4 py-3 opacity-60 cursor-not-allowed select-none") do
        div(class: "flex items-center gap-2 text-purple-400 text-sm font-medium mb-2") do
          span { "🪄" }
          span { "Recommend" }
        end
        div(class: "flex gap-2") do
          div(class: "flex-1 bg-white rounded-lg px-3 py-2 text-xs text-purple-300 border border-purple-100 text-center") { "Things I would like" }
          div(class: "flex-1 bg-white rounded-lg px-3 py-2 text-xs text-purple-300 border border-purple-100 text-center") { "Things I might like" }
        end
      end
    end
  end

  def render_empty_state
    div(class: "bg-white rounded-lg shadow-md p-12 text-center") do
      div(class: "text-8xl mb-6") { "📚" }
      h2(class: "text-3xl font-bold text-gray-800 mb-4") { "Your shelf is empty" }
      p(class: "text-lg text-gray-500 mb-8") { "Scan a barcode to add your first item." }
      a(
        href: scanner_path,
        class: "inline-flex items-center gap-2 bg-primary-600 text-white px-8 py-4 rounded-lg hover:bg-primary-700 transition-colors font-semibold text-lg shadow-lg"
      ) do
        span { "📱" }
        span { "Start Scanning" }
      end
    end
  end
end
