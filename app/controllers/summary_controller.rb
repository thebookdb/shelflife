class SummaryController < ApplicationController
  def dashboard
    libraries_with_items = Library.order(:name).map do |library|
      recent_items = library.library_items
        .includes(:product)
        .order(date_added: :desc)
        .limit(5)
      {library: library, items: recent_items}
    end

    show_onboarding = Current.user && !Current.user.get_setting("onboarding_dismissed", false)

    render Components::Summary::DashboardView.new(
      libraries_with_items: libraries_with_items,
      show_onboarding: show_onboarding
    )
  end
end
