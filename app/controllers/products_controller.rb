class ProductsController < ApplicationController
  before_action :find_or_create_product, only: [:show]

  def index
    recent_products = if Current.user
      Product.joins(:library_items)
        .where(library_items: {added_by: Current.user})
        .order("library_items.date_added DESC")
        .distinct
        .limit(5)
    else
      []
    end

    render Components::Products::IndexView.new(recent_products: recent_products)
  end

  def show
    # Trigger high-priority enrichment if product needs it
    ProductDataFetchJob.perform_later(@product, false) unless @product.enriched?

    # Regular page view
    render Components::Products::ShowView.new(product: @product)
  end

  def refresh
    @product = Product.find(params[:id])
    ProductDataFetchJob.perform_later(@product, true)

    redirect_to "/#{@product.gtin}", notice: "Refreshing data for #{@product.safe_title}..."
  end

  def destroy
    @product = Product.find(params[:id])
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
