class ProductsController < ApplicationController
  before_action :find_or_create_product, only: [ :show ]

  def index
    # Get recent products from user's scans
    recent_products = if Current.user
      Product.joins(:scans)
        .where(scans: { user: Current.user })
        .order("scans.scanned_at DESC")
        .distinct
        .limit(5)
    else
      []
    end

    render Components::Products::IndexView.new(recent_products: recent_products)
  end

  def show
    # Trigger high-priority enrichment if product needs it
    ProductDataFetchJob.set(queue: :high_priority).perform_later(@product, false) unless @product.enriched?

    # Regular page view
    render Components::Products::ShowView.new(product: @product)
  end

  def add_to_library
    @product = Product.find(params[:id])
    library_name = params[:library_name] || "Home"
    library = Library.find_by(name: library_name)

    if library
      # Check if already in this library
      existing_item = @product.library_items.find_by(library: library)

      if existing_item
        flash[:alert] = "#{@product.title} is already in #{library.name}"
      else
        @product.library_items.create!(
          library: library,
          condition: params[:condition] || "good",
          notes: params[:notes]
        )

        flash[:notice] = "Added #{@product.title} to #{library.name}"
      end
    else
      flash[:alert] = "Library not found"
    end

    # Return updated product display
    render turbo_stream: turbo_stream.replace(
      "product-display",
      Components::Products::DisplayView.new(product: @product)
    )
  end

  def remove_from_library
    @product = Product.find(params[:id])
    library_name = params[:library_name]
    library = Library.find_by(name: library_name)

    if library
      library_item = @product.library_items.find_by(library: library)
      if library_item
        library_item.destroy
        flash[:notice] = "Removed #{@product.title} from #{library.name}"
      else
        flash[:alert] = "#{@product.title} was not in #{library.name}"
      end
    else
      flash[:alert] = "Library not found"
    end

    # Return updated product display
    render turbo_stream: turbo_stream.replace(
      "product-display",
      Components::Products::DisplayView.new(product: @product)
    )
  end

  def refresh
    @product = Product.find(params[:id])
    ProductDataFetchJob.set(queue: :high_priority).perform_later(@product, true)

    redirect_to "/#{@product.gtin}", notice: "Refreshing data for #{@product.safe_title}..."
  end

  def destroy
    @product = Product.find(params[:id])
    product_title = @product.safe_title

    @product.destroy

    redirect_to root_path, notice: "#{product_title} and all associated scans have been deleted."
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
