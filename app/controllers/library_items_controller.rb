class LibraryItemsController < ApplicationController
  # include Rails.application.routes.url_helpers

  def create
    @product = Product.find(params[:product_id])
    @library = Library.find(params[:library_id]) # Assuming library_id is passed
    @library_item = LibraryItem.new(product: @product, library: @library)

    if @library_item.save
      redirect_back_or_to product_path(@product), notice: "Added to library!"
    else
      redirect_back_or_to product_path(@product), alert: "Couldn't add to library."
    end
  end

  def destroy
    @library_item = LibraryItem.find(params[:id])
    @library_item.destroy
    redirect_back_or_to libraries_path, notice: "Removed from library."
  end
end
