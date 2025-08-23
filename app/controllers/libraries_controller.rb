class LibrariesController < ApplicationController
  def index
    @libraries = Library.includes(:library_items).all
    render Components::Libraries::IndexView.new(libraries: @libraries)
  end

  def show
    @library = Library.find(params[:id])

    library_items = @library.library_items.includes(:product)

    # Filter out invalid barcodes if user has that setting enabled
    if Current.user.hide_invalid_barcodes?
      library_items = library_items.joins(:product).where(products: { valid_barcode: true })
    end

    @pagy, @library_items = pagy(library_items)
    render Components::Libraries::ShowView.new(library: @library, library_items: @library_items, pagy: @pagy)
  end
end
