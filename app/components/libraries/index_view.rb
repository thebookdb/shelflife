class Components::Libraries::IndexView < Components::Base
  # include Rails.application.routes.url_helpers

  def initialize(libraries:)
    @libraries = libraries
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      render Components::Shared::NavigationView.new

      div(class: "pt-20 px-4") do
        div(class: "max-w-4xl mx-auto") do
          div(class: "mb-8") do
            h1(class: "text-3xl font-bold text-gray-900") { "Libraries" }
            p(class: "text-gray-600 mt-2") { "Browse our shared collections" }
          end

          if @libraries.any?
            div(class: "grid gap-4") do
              @libraries.each do |library|
                render_library(library)
              end
            end
          else
            div(class: "bg-white rounded-lg shadow-md p-8 text-center") do
              div(class: "text-6xl mb-4") { "📚" }
              h2(class: "text-xl font-semibold text-gray-800 mb-2") { "No libraries yet" }
              p(class: "text-gray-600 mb-4") { "Libraries will appear here once they're created" }
            end
          end
        end
      end
    end
  end

  private

  def render_library(library)
    item_count = library.library_items.size

    div(class: "bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow") do
      div(class: "flex items-center justify-between") do
        div(class: "flex-1") do
          h3(class: "text-xl font-semibold text-gray-900 mb-2") { library.name }
          if library.description.present?
            p(class: "text-gray-600 mb-3") { library.description }
          end

          div(class: "flex items-center text-sm text-gray-500") do
            span(class: "bg-gray-100 px-3 py-1 rounded-full") do
              "#{item_count} #{'item'.pluralize(item_count)}"
            end
          end
        end

        div(class: "ml-4") do
          a(
            href: library_path(library),
            class: "bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
          ) { "Browse Items" }
        end
      end
    end
  end
end
