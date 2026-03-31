class LibraryItemsController < ApplicationController
  before_action :set_library_item, only: [:show, :edit, :update, :destroy]

  def create
    handle_scanner_create if params[:gtin]
    handle_exist_checkbox unless params[:gtin]
  end

  def show
    @libraries = Library.for_user(Current.user)
    render Components::LibraryItems::ShowView.new(library_item: @library_item, libraries: @libraries)
  end

  def edit
    render Components::LibraryItems::EditView.new(library_item: @library_item)
  end

  def update
    # Convert tags string to array if present
    if params[:library_item][:tags].present?
      params[:library_item][:tags] = params[:library_item][:tags].split(",").map(&:strip).reject(&:blank?)
    end

    # Update product genre if provided
    if params[:product].present? && params[:product][:genre].present?
      @library_item.product.update(genre: params[:product][:genre])
    elsif params[:product].present? && params[:product][:genre] == ""
      @library_item.product.update(genre: nil)
    end

    if @library_item.update(library_item_params.merge(updated_by: Current.user))
      return_to = params[:return_to]
      redirect_path = (return_to&.match?(%r{\A/[^/]}) ? return_to : nil) || library_path(@library_item.library)
      redirect_to redirect_path, notice: "Item updated successfully."
    else
      render Components::LibraryItems::EditView.new(library_item: @library_item), status: :unprocessable_entity
    end
  end

  def destroy
    @product = @library_item.product
    @library = @library_item.library

    @library_item.destroy
    Turbo::StreamsChannel.broadcast_refresh_to("library_#{@library.id}")

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to libraries_path, notice: "Removed from library." }
    end
  end

  private

  def set_library_item
    @library_item = LibraryItem.find(params[:id])
  end

  def library_item_params
    params.require(:library_item).permit(
      :library_id,
      :location,
      :condition_id,
      :condition_notes,
      :notes,
      :private_notes,
      :acquisition_date,
      :acquisition_price,
      :acquisition_source_id,
      :ownership_status_id,
      :item_status_id,
      :copy_identifier,
      :replacement_cost,
      :original_retail_price,
      :current_market_value,
      :is_favorite,
      :intent,
      tags: []
    )
  end

  def handle_exist_checkbox
    @product = Product.find(params[:library_item][:product_id])
    @library = Library.find(params[:library_item][:library_id])

    # Find existing library_item
    existing_item = LibraryItem.find_by(product: @product, library: @library)

    if params[:library_item][:exist] == "1"
      # Checkbox is checked - create if doesn't exist
      if existing_item.nil?
        @library_item = LibraryItem.new(product: @product, library: @library, added_by: Current.user, intent: @library.default_intent)
        @library_item.save
      else
        @library_item = existing_item
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back_or_to product_path(@product), notice: "Added to library!" }
      end
    else
      # Checkbox is unchecked - destroy if exists
      if existing_item
        @library_item = existing_item
        @library_item.destroy
      end

      respond_to do |format|
        format.turbo_stream { render :destroy }
        format.html { redirect_back_or_to product_path(@product), notice: "Removed from library." }
      end
    end
  end

  def handle_scanner_create
    gtin = params[:gtin]
    library = params[:library_id].present? ? Library.find(params[:library_id]) : Current.user.default_library

    product = Product.find_or_create_by_gtin(gtin)
    ProductDataFetchJob.perform_later(product, false) unless product.enriched?

    existing_item = LibraryItem.find_by(product: product, library: library)
    @library_item = existing_item || LibraryItem.create!(
      product: product,
      library: library,
      added_by: Current.user,
      intent: library.default_intent
    )

    # Broadcast refresh to library show page for real-time updates
    if @library_item.persisted? && !existing_item
      Turbo::StreamsChannel.broadcast_refresh_to("library_#{library.id}")
    end

    respond_to do |format|
      format.turbo_stream
      format.json { head :created }
      format.html { head :created }
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue ArgumentError => e
    Rails.logger.error "Invalid GTIN: #{e.message}"
    head :bad_request
  end
end
