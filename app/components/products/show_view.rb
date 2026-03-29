class Components::Products::ShowView < Components::Base
  def initialize(product:)
    @product = product
  end

  def view_template
    div(class: "min-h-screen bg-gray-50 pt-16") do
      div(class: "py-4") do
        # Breadcrumb and header
        div(class: "max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 mb-4") do
          nav(class: "text-sm text-gray-600 mb-4") do
            a(href: products_path, class: "hover:text-slate-600") { "Products" }
            plain " / "
            span(class: "text-gray-900 font-medium") { @product.safe_title }
          end

          h1(class: "text-3xl font-bold text-gray-900") { "About This Product" }
        end

        render Components::Products::DisplayView.new(product: @product)
      end
    end
  end
end
