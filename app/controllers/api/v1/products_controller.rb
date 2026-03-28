class Api::V1::ProductsController < Api::V1::BaseController
  def index
    @products = Product.page(params[:page])
    render_json_success(
      products: @products.map { |p| product_json(p) },
      pagination: pagination_json(@products)
    )
  end

  def show
    @product = Product.find(params[:id])
    render_json_success(product: product_json(@product))
  rescue ActiveRecord::RecordNotFound
    render_json_error("Product not found", :not_found)
  end

  private

  def product_json(product)
    {
      id: product.id,
      gtin: product.gtin,
      title: product.title,
      author: product.author,
      publisher: product.publisher,
      product_type: product.product_type,
      enriched: product.enriched?,
      created_at: product.created_at,
      updated_at: product.updated_at
    }
  end

  def pagination_json(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end
