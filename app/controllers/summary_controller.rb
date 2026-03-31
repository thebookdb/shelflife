class SummaryController < ApplicationController
  def dashboard
    libraries = Library.for_user(Current.user).includes(library_items: :product)
    dashboard_settings = Current.user.user_settings

    libraries_with_items = libraries.map do |library|
      items = library.library_items.sort_by { |li| li.date_added || Time.at(0) }.last(20).reverse
      group_by = dashboard_settings["library_#{library.id}_group_by"] || "genre"
      {library: library, items: items, group_by: group_by}
    end

    trophy_items = libraries.flat_map { |lib| lib.library_items.select(&:is_favorite) }
      .sort_by(&:updated_at).last(20).reverse

    show_onboarding = Current.user && !Current.user.get_setting("onboarding_dismissed", false)

    render Components::Summary::DashboardView.new(
      libraries_with_items: libraries_with_items,
      trophy_items: trophy_items,
      show_onboarding: show_onboarding
    )
  end
end
