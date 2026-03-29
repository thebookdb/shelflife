class ProductsController < ApplicationController
  before_action :find_or_create_product, only: [:show]

  def index
    products = Product.includes(:library_items).order(:title)
    show_onboarding = Current.user && !Current.user.get_setting("onboarding_dismissed", false)

    render Components::Products::IndexView.new(products: products, show_onboarding: show_onboarding)
  end

  def new
    render Components::Products::NewView.new
  end

  def create
    gtin = params[:gtin].to_s.strip
    product_type = params[:product_type].presence || "book"

    begin
      product = Product.find_or_create_by_gtin(gtin, {product_type: product_type})
      redirect_to gtin_path(product), notice: "#{product.safe_title} added."
    rescue ArgumentError => e
      render Components::Products::NewView.new(gtin: gtin, error: e.message), status: :unprocessable_entity
    end
  end

  def show
    # Trigger high-priority enrichment if product needs it
    ProductDataFetchJob.perform_later(@product, false) unless @product.enriched?

    # Regular page view
    render Components::Products::ShowView.new(product: @product)
  end

  def refresh
    @product = Product.find_by!(gtin: params[:id])
    ProductDataFetchJob.perform_later(@product, true)

    redirect_to gtin_path(@product), notice: "Refreshing data for #{@product.safe_title}..."
  end

  def destroy
    @product = Product.find_by!(gtin: params[:id])
    product_title = @product.safe_title
    library_ids = @product.libraries.distinct.pluck(:id)

    @product.destroy

    library_ids.each { |id| Turbo::StreamsChannel.broadcast_refresh_to("library_#{id}") }

    redirect_to root_path, notice: "#{product_title} has been deleted."
  end

  private

  def find_or_create_product
    gtin = params[:gtin] || params[:id]

    begin
      @product = Product.find_or_create_by_gtin(gtin, {
        product_type: "book" # Default assumption
      })
    rescue ArgumentError => e
      redirect_to root_path, alert: e.message
    end
  end
end
