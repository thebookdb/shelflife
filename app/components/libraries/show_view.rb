class Components::Libraries::ShowView < Components::Base
  include ActionView::Helpers::FormTagHelper
  include Phlex::Rails::Helpers::TurboStreamFrom
  def initialize(library:, products: [], grouped_items: {}, pagy: nil)
    @library = library
    @products = products
    @grouped_items = grouped_items
    @pagy = pagy
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      render Components::Shared::NavigationView.new
      
      # Subscribe to library updates for real-time product enrichment
      turbo_cable_stream_source(
        channel: "Turbo::StreamsChannel", 
        signed_stream_name: Turbo::StreamsChannel.signed_stream_name("library_#{@library.id}")
      )

      div(class: "pt-20 px-4", id: "blahblahblah") do
        div(class: "max-w-7xl mx-auto") do
          div(class: "mb-8") do
            div(class: "flex items-center justify-between") do
              div do
                h1(class: "text-3xl font-bold text-gray-900") { @library.name }
                if @library.description.present?
                  p(class: "text-gray-600 mt-2") { @library.description }
                end
              end
            end
          end

          if @products.any?
            # Pagination at top
            render_pagination if @pagy && @pagy.pages > 1

            # Render grouped products
            div(class: "mt-4") do
              @products.each do |product|
                library_items = @grouped_items[product]
                render Components::Libraries::ProductGroupView.new(
                  product: product,
                  library_items: library_items
                )
              end
            end

            # Pagination and action buttons at bottom
            div(class: "mt-8") do
              div(class: "flex justify-center") do
                render_pagination if @pagy && @pagy.pages > 1
              end

              div(class: "flex justify-center gap-2 mt-4") do
                a(href: import_library_path(@library), class: "bg-green-600 text-white px-3 py-1.5 text-sm rounded-lg hover:bg-green-700 transition-colors") { "Import" }
                a(href: export_library_path(@library, format: :csv), class: "bg-purple-600 text-white px-3 py-1.5 text-sm rounded-lg hover:bg-purple-700 transition-colors") { "Export CSV" }
                a(href: edit_library_path(@library), class: "bg-blue-600 text-white px-3 py-1.5 text-sm rounded-lg hover:bg-blue-700 transition-colors") { "Edit Library" }
              end
            end
          else
            div(class: "bg-white rounded-lg shadow-md p-8 text-center") do
              div(class: "text-6xl mb-4") { "📚" }
              h2(class: "text-xl font-semibold text-gray-800 mb-2") { "#{@library.name} is empty" }
              p(class: "text-gray-600 mb-4") { "No items have been added to this library yet" }
              a(href: root_path, class: "bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors") do
                "Start Scanning"
              end
            end
          end
        end
      end
    end
  end

  private

  def render_pagination
    nav(class: "flex items-center gap-1 text-sm") do
        # Previous link
        if @pagy.prev
          a(href: library_path(@library, page: @pagy.prev),
            class: "text-blue-600 hover:text-blue-800 hover:underline px-2") do
            "← Previous"
          end
        else
          span(class: "text-gray-400 px-2") do
            "← Previous"
          end
        end

        span(class: "text-gray-400 mx-1") { "|" }

        # Page numbers
        start_page = [@pagy.page - 2, 1].max
        end_page = [@pagy.page + 2, @pagy.pages].min

        (start_page..end_page).each do |page_num|
          if page_num == @pagy.page
            span(class: "font-semibold text-gray-900 px-2") do
              page_num.to_s
            end
          else
            a(href: library_path(@library, page: page_num),
              class: "text-blue-600 hover:text-blue-800 hover:underline px-2") do
              page_num.to_s
            end
          end
        end

        span(class: "text-gray-400 mx-1") { "|" }

        # Next link
        if @pagy.next
          a(href: library_path(@library, page: @pagy.next),
            class: "text-blue-600 hover:text-blue-800 hover:underline px-2") do
            "Next →"
          end
        else
          span(class: "text-gray-400 px-2") do
            "Next →"
          end
        end
      end
    end

end
