class Components::Products::ShowView < Phlex::HTML
  def initialize(product:)
    @product = product
  end

  def view_template
    # Render the display component inside a turbo frame for the show page
    render Components::Products::DisplayView.new(product: @product)
  end
end
