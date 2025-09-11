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

  def edit
    @library = Library.find(params[:id])
    render Components::Libraries::EditView.new(library: @library)
  end

  def update
    @library = Library.find(params[:id])
    
    if @library.update(library_params)
      redirect_to library_path(@library), notice: "Library updated successfully."
    else
      render Components::Libraries::EditView.new(library: @library), status: :unprocessable_entity
    end
  end

  private

  def library_params
    params.require(:library).permit(:name, :description)
  end
end
