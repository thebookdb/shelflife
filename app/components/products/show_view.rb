class Components::Products::ShowView < Phlex::HTML
  def initialize(product:)
    @product = product
  end

  def view_template
    div(class: "min-h-screen bg-gray-50 pt-16") do
      # Content Area
      div(class: "py-4") do
        render Components::Products::DisplayView.new(product: @product)
      end
    end
  end
end
