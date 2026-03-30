class Components::Summary::DashboardView < Components::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken

  GROUP_BY_OPTIONS = {
    "genre" => "Genre",
    "product_type" => "Type",
    "author" => "Author",
    "none" => "None"
  }.freeze

  def initialize(libraries_with_items: [], show_onboarding: false)
    @libraries_with_items = libraries_with_items
    @show_onboarding = show_onboarding
  end

  def view_template
    render Components::Shared::OnboardingModalView.new if @show_onboarding

    div(class: "min-h-screen bg-gray-50 pt-16") do
      div(class: "py-8 max-w-6xl mx-auto px-4") do
        h1(class: "text-3xl font-bold text-gray-900 mb-6") { "Dashboard" }
        if @libraries_with_items.empty?
          render_empty_state
        else
          @libraries_with_items.each_with_index do |entry, index|
            render_library_section(entry[:library], entry[:items], entry[:group_by], index)
          end
        end
      end
    end
  end

  private

  def render_library_section(library, items, group_by, index)
    div(class: "mb-6 bg-white rounded-xl shadow-sm border border-gray-100 p-6") do
      render_library_header(library, group_by, index)

      if items.any?
        render_grouped_items(items, group_by)
      else
        div(class: "text-gray-400 text-base italic py-4") { "No items yet — scan something!" }
      end

      render_recommendations
    end
  end

  def render_library_header(library, group_by, index)
    div(class: "flex items-center justify-between mb-4") do
      div(class: "flex items-baseline gap-3") do
        a(href: library_path(library), class: "hover:text-primary-600 transition-colors") do
          h2(class: "text-xl font-bold text-gray-900") { library.name }
        end
        if library.description.present?
          span(class: "text-sm text-gray-400") { library.description }
        end
      end

      div(
        class: "relative",
        data: {
          controller: "dashboard-settings",
          "dashboard-settings-library-id-value": library.id
        }
      ) do
        button(
          type: "button",
          class: "p-1.5 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100 transition-colors",
          data: {action: "click->dashboard-settings#toggle"}
        ) do
          svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 20 20", fill: "currentColor", class: "w-5 h-5") do |s|
            s.path(
              fill_rule: "evenodd",
              d: "M7.84 1.804A1 1 0 018.82 1h2.36a1 1 0 01.98.804l.331 1.652a6.993 6.993 0 011.929 1.115l1.598-.54a1 1 0 011.186.447l1.18 2.044a1 1 0 01-.205 1.251l-1.267 1.113a7.047 7.047 0 010 2.228l1.267 1.113a1 1 0 01.206 1.25l-1.18 2.045a1 1 0 01-1.187.447l-1.598-.54a6.993 6.993 0 01-1.929 1.115l-.33 1.652a1 1 0 01-.98.804H8.82a1 1 0 01-.98-.804l-.331-1.652a6.993 6.993 0 01-1.929-1.115l-1.598.54a1 1 0 01-1.186-.447l-1.18-2.044a1 1 0 01.205-1.251l1.267-1.114a7.05 7.05 0 010-2.227L1.821 7.773a1 1 0 01-.206-1.25l1.18-2.045a1 1 0 011.187-.447l1.598.54A6.993 6.993 0 017.51 3.456l.33-1.652zM10 13a3 3 0 100-6 3 3 0 000 6z",
              clip_rule: "evenodd"
            )
          end
        end

        div(
          class: "hidden absolute right-0 top-8 z-20 bg-white border border-gray-200 rounded-lg shadow-lg w-48",
          data: {"dashboard-settings-target": "menu"}
        ) do
          div(class: "p-2") do
            p(class: "text-xs font-medium text-gray-400 uppercase tracking-wide px-2 py-1") { "Group by" }
            GROUP_BY_OPTIONS.each do |value, label|
              active = value == group_by
              button(
                type: "button",
                class: "w-full text-left px-2 py-1.5 text-sm rounded #{active ? "bg-orange-50 text-orange-700 font-medium" : "text-gray-700 hover:bg-gray-50"}",
                data: {action: "click->dashboard-settings#setGroupBy", value: value}
              ) do
                plain label
                if active
                  plain " "
                  span(class: "text-orange-500") { "✓" }
                end
              end
            end

            div(class: "border-t border-gray-100 mt-1 pt-1") do
              p(class: "text-xs font-medium text-gray-400 uppercase tracking-wide px-2 py-1") { "Order" }
              if index > 0
                button(
                  type: "button",
                  class: "w-full text-left px-2 py-1.5 text-sm text-gray-700 hover:bg-gray-50 rounded",
                  data: {action: "click->dashboard-settings#moveUp"}
                ) { "Move up" }
              end
              if index < @libraries_with_items.size - 1
                button(
                  type: "button",
                  class: "w-full text-left px-2 py-1.5 text-sm text-gray-700 hover:bg-gray-50 rounded",
                  data: {action: "click->dashboard-settings#moveDown"}
                ) { "Move down" }
              end
            end
          end
        end
      end
    end
  end

  def render_grouped_items(items, group_by)
    if group_by == "none"
      div(class: "flex gap-4 overflow-x-auto pb-2") do
        items.each { |item| render_book_card(item) }
      end
      return
    end

    grouped = items.group_by { |item| group_value(item, group_by) }
    named_groups = grouped.except(nil).sort_by { |_, v| -v.size }
    ungrouped = grouped[nil] || []

    rows_shown = 0

    named_groups.each do |label, group_items|
      break if rows_shown >= 3

      p(class: "text-xs font-medium text-gray-400 uppercase tracking-wide mt-3 mb-1.5") { label }
      div(class: "flex gap-4 overflow-x-auto pb-2") do
        group_items.each { |item| render_book_card(item) }
      end
      rows_shown += 1
    end

    if ungrouped.any? && rows_shown < 3
      if named_groups.any?
        p(class: "text-xs font-medium text-gray-400 uppercase tracking-wide mt-3 mb-1.5") { "Other" }
      end
      div(class: "flex gap-4 overflow-x-auto pb-2") do
        ungrouped.each { |item| render_book_card(item) }
      end
    end
  end

  def group_value(item, group_by)
    case group_by
    when "genre"
      item.product.genre.presence
    when "product_type"
      item.product.product_type&.humanize
    when "author"
      item.product.author.presence
    end
  end

  def render_book_card(library_item)
    product = library_item.product

    a(href: library_item_path(library_item), class: "flex-shrink-0 group w-28") do
      div(class: "w-28 h-40 rounded-lg overflow-hidden shadow-md mb-2 bg-gray-200 border-b-4 #{intent_border_class(library_item)} group-hover:shadow-lg transition-shadow") do
        if product.cover_image.attached?
          img(src: url_for(product.cover_image), alt: product.title, class: "w-full h-full object-cover")
        elsif product.cover_image_url.present?
          img(src: product.cover_image_url, alt: product.title, class: "w-full h-full object-cover")
        else
          div(class: "w-full h-full flex items-center justify-center") do
            span(class: "text-4xl") { "📚" }
          end
        end
      end
      p(class: "text-xs font-semibold text-gray-800 leading-tight line-clamp-2 group-hover:text-primary-600 transition-colors") { product.title }
      if product.author.present?
        p(class: "text-xs text-gray-400 mt-0.5 truncate") { product.author }
      end
    end
  end

  def render_recommendations
    div(class: "mt-5 flex gap-3") do
      div(class: "flex items-center gap-2 px-3 py-2 rounded-lg bg-indigo-50 border border-indigo-100 text-indigo-400 text-xs font-medium opacity-60 cursor-not-allowed select-none") do
        span { "🚀 Explore" }
      end

      div(class: "flex items-center gap-2 px-3 py-2 rounded-lg bg-purple-50 border border-purple-100 text-purple-400 text-xs font-medium opacity-60 cursor-not-allowed select-none") do
        span { "🪄 Recommend" }
      end
    end
  end

  def render_empty_state
    div(class: "bg-white rounded-lg shadow-md p-12 text-center") do
      div(class: "text-8xl mb-6") { "📚" }
      h2(class: "text-3xl font-bold text-gray-800 mb-4") { "Your shelf is empty" }
      p(class: "text-lg text-gray-500 mb-8") { "Scan a barcode to add your first item." }
      a(
        href: scanner_path,
        class: "inline-flex items-center gap-2 bg-primary-600 text-white px-8 py-4 rounded-lg hover:bg-primary-700 transition-colors font-semibold text-lg shadow-lg"
      ) do
        span { "📱" }
        span { "Start Scanning" }
      end
    end
  end
end
