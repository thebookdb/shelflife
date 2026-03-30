class SummaryController < ApplicationController
  def dashboard
    libraries = Library.where(user: [Current.user, nil]).includes(library_items: :product)
    library_order = Current.user.get_setting("dashboard_library_order", []).map(&:to_s)
    dashboard_settings = Current.user.user_settings

    ordered = if library_order.any?
      libraries.sort_by { |lib| library_order.index(lib.id.to_s) || Float::INFINITY }
    else
      libraries.order(:name)
    end

    libraries_with_items = ordered.map do |library|
      items = library.library_items.sort_by { |li| li.date_added || Time.at(0) }.last(20).reverse
      group_by = dashboard_settings["library_#{library.id}_group_by"] || "genre"
      {library: library, items: items, group_by: group_by}
    end

    show_onboarding = Current.user && !Current.user.get_setting("onboarding_dismissed", false)

    render Components::Summary::DashboardView.new(
      libraries_with_items: libraries_with_items,
      show_onboarding: show_onboarding
    )
  end
end
