class ScannersController < ApplicationController
  def index
    @recent_items = recent_scanned_items
    @libraries = Library.order(:name)

    render Components::Scanners::IndexView.new(
      recent_items: @recent_items,
      libraries: @libraries
    )
  end

  def horizontal
    @recent_items = recent_scanned_items
    @libraries = Library.order(:name)

    render Components::Scanners::HorizontalView.new(
      recent_items: @recent_items,
      libraries: @libraries
    )
  end

  def set_library
    library_id = params[:library_id]

    if library_id.present?
      library = Library.find_by(id: library_id)
      session[:current_library_gid] = library&.to_global_id&.to_s
    else
      session[:current_library_gid] = nil
    end

    head :ok
  end

  private

  def recent_scanned_items
    LibraryItem.where(added_by: Current.user)
      .includes(:product, :library)
      .order(date_added: :desc)
      .limit(10)
  end
end
