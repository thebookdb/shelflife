class ScansController < ApplicationController
  def index
    recent_scans = Current.user.scans.includes(:product, :user).recent.last_n(20)

    # Filter out invalid barcodes if user has that setting enabled
    if Current.user.hide_invalid_barcodes?
      recent_scans = recent_scans.joins(:product).where(products: { valid_barcode: true })
    end

    render Components::Scans::IndexView.new(recent_scans: recent_scans)
  end

  def create
    # Accept either product_id or gtin parameter
    if params[:product_id]
      product = Product.find(params[:product_id])
    elsif params[:gtin]
      product = Product.find_or_create_by_gtin(params[:gtin])
    else
      head :bad_request
      return
    end

    # Track the scan
    Scan.track_scan(product, user: Current.user)

    # If Current.library is set, add to that library
    if Current.library
      # Check if already in this library
      existing_item = product.library_items.find_by(library: Current.library)
      unless existing_item
        product.library_items.create!(
          library: Current.library,
          condition: "good",
          notes: nil
        )
      end
    end

    head :created
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue ArgumentError => e
    Rails.logger.error "Invalid GTIN: #{e.message}"
    head :bad_request
  rescue => e
    Rails.logger.error "Failed to track scan: #{e.message}"
    head :unprocessable_entity
  end
end
