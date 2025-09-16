class ScannersController < ApplicationController
  def index
    # Get recent scans for the scanning list (last 10 for mobile view)
    @recent_scans = Current.user.scans.includes(:product, :user).recent.last_n(10)

    # Get available libraries for the dropdown
    @libraries = Library.all.order(:name)

    render Components::Scanners::IndexView.new(
      recent_scans: @recent_scans,
      libraries: @libraries
    )
  end

  def horizontal
    # Get recent scans for the scanning list (last 10 for mobile view)
    @recent_scans = Current.user.scans.includes(:product, :user).recent.last_n(10)

    # Get available libraries for the dropdown
    @libraries = Library.all.order(:name)

    render Components::Scanners::HorizontalView.new(
      recent_scans: @recent_scans,
      libraries: @libraries
    )
  end

  def set_library
    library_name = params[:library_name]

    if library_name.present?
      library = Library.find_by(name: library_name)
      session[:current_library_gid] = library&.to_global_id&.to_s
    else
      session[:current_library_gid] = nil
    end

    head :ok
  end
end
