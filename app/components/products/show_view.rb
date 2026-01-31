class Components::Products::ShowView < Phlex::HTML
  def initialize(product:)
    @product = product
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      # Header Section
      div(class: "bg-white shadow-sm border-b border-gray-200") do
        div(class: "py-6") do
          div(class: "flex items-center justify-between mb-2") do
            h1(class: "text-2xl font-bold text-gray-800") { "Product Details" }
            div(class: "flex gap-3") do
              a(
                href: "/scanner",
                class: "bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors text-sm font-medium flex items-center gap-2"
              ) do
                span { "📱" }
                span { "Scan" }
              end
              a(
                href: "/",
                class: "text-blue-600 hover:text-blue-800 text-sm font-medium flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-blue-50 transition-colors"
              ) do
                span { "🏠" }
                span { "Home" }
              end
            end
          end
          p(class: "text-gray-600") { "View and manage product information" }
        end
      end

      # Content Area
      div(class: "py-6") do
        render Components::Products::DisplayView.new(product: @product)
      end
    end
  end
end
