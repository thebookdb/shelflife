class LibraryItemsController < ApplicationController
  before_action :set_library_item, only: [:show, :edit, :update, :destroy]

  def show
    render Components::LibraryItems::ShowView.new(library_item: @library_item)
  end

  def edit
    render Components::LibraryItems::EditView.new(library_item: @library_item)
  end

  def update
    # Convert tags string to array if present
    if params[:library_item][:tags].present?
      params[:library_item][:tags] = params[:library_item][:tags].split(',').map(&:strip).reject(&:blank?)
    end

    if @library_item.update(library_item_params)
      redirect_to library_path(@library_item.library), notice: "Item updated successfully."
    else
      render Components::LibraryItems::EditView.new(library_item: @library_item), status: :unprocessable_entity
    end
  end

  def create
    handle_exist_checkbox
  end

  def destroy
    @product = @library_item.product
    @library = @library_item.library

    @library_item.destroy

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
      :lent_to,
      :due_date,
      :is_favorite,
      tags: []
    )
  end

  def handle_exist_checkbox
    @product = Product.find(params[:library_item][:product_id])
    @library = Library.find(params[:library_item][:library_id])
    
    # Find existing library_item
    existing_item = LibraryItem.find_by(product: @product, library: @library)
    
    if params[:library_item][:exist] == '1'
      # Checkbox is checked - create if doesn't exist
      if existing_item.nil?
        @library_item = LibraryItem.new(product: @product, library: @library)
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
end
