class LibraryItemsController < ApplicationController
  def create
    handle_exist_checkbox
  end

  def destroy
    @library_item = LibraryItem.find(params[:id])
    @product = @library_item.product
    @library = @library_item.library
    
    @library_item.destroy
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to libraries_path, notice: "Removed from library." }
    end
  end

  private

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
