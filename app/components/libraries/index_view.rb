class Components::Libraries::IndexView < Components::Base
  def initialize(libraries:)
    @libraries = libraries
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      render Components::Shared::NavigationView.new

      div(class: "pt-16 px-4") do
        div(class: "max-w-4xl mx-auto") do
          div(class: "mb-6 flex items-center justify-between") do
            div do
              h1(class: "text-3xl font-bold text-gray-900") { "Libraries" }
              p(class: "text-gray-600 mt-2") { "Organise your things" }
            end
            a(
              href: new_library_path,
              class: "bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors text-sm"
            ) { "New Library" }
          end

          div(class: "grid gap-3") do
            @libraries.each { |library| render_library(library) }
          end
        end
      end
    end
  end

  private

  def render_library(library)
    item_count = library.library_items.size

    div(class: "bg-white rounded-lg shadow-sm p-5 hover:shadow-md transition-shadow") do
      div(class: "flex items-center justify-between") do
        div(class: "flex-1") do
          h3(class: "text-lg font-semibold text-gray-900") { library.name }
          if library.description.present?
            p(class: "text-gray-500 text-sm mt-0.5") { library.description }
          end
          div(class: "mt-2") do
            span(class: "bg-gray-100 text-gray-600 text-xs px-2.5 py-1 rounded-full") do
              "#{item_count} #{"item".pluralize(item_count)}"
            end
          end
        end

        a(
          href: library_path(library),
          class: "ml-4 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors text-sm"
        ) { "Browse" }
      end
    end
  end
end
