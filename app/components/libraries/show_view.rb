class Components::Libraries::ShowView < Components::Base
  include ActionView::Helpers::FormTagHelper
  include Phlex::Rails::Helpers::TurboStreamFrom
  def initialize(library:, library_items:, pagy: nil)
    @library = library
    @library_items = library_items
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
        div(class: "max-w-4xl mx-auto") do
          div(class: "mb-8") do
            div(class: "flex items-center justify-between") do
              div do
                h1(class: "text-3xl font-bold text-gray-900") { @library.name }
                if @library.description.present?
                  p(class: "text-gray-600 mt-2") { @library.description }
                end
              end

              div(class: "flex gap-2") do
                a(href: import_library_path(@library), class: "bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors") { "Import" }
                a(href: export_library_path(@library, format: :csv), class: "bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700 transition-colors") { "Export CSV" }
                a(href: edit_library_path(@library), class: "bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors") { "Edit Library" }
              end
            end
          end

          if @library_items.any?
            # Pagination at top
            render_pagination if @pagy && @pagy.pages > 1
            
            div(class: "grid gap-4") do
              @library_items.each do |library_item|
                render Components::Libraries::LibraryItemView.new(library_item: library_item)
              end
            end

            # Pagination at bottom
            render_pagination if @pagy && @pagy.pages > 1
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
    div(class: "mt-8 flex justify-center") do
      nav(class: "flex space-x-2") do
        # Previous button
        if @pagy.prev
          a(href: library_path(@library, page: @pagy.prev),
            class: "px-3 py-2 bg-white border rounded-md hover:bg-gray-50") do
            "Previous"
          end
        else
          span(class: "px-3 py-2 text-gray-300 bg-gray-100 border rounded-md cursor-not-allowed") do
            "Previous"
          end
        end

        # Page numbers
        start_page = [@pagy.page - 2, 1].max
        end_page = [@pagy.page + 2, @pagy.pages].min

        (start_page..end_page).each do |page_num|
          if page_num == @pagy.page
            span(class: "px-3 py-2 text-white bg-blue-600 border rounded-md mr-1") do
              page_num.to_s
            end
          else
            a(href: library_path(@library, page: page_num),
              class: "px-3 py-2 bg-white border rounded-md hover:bg-gray-50 mr-1") do
              page_num.to_s
            end
          end
        end

        # Next button  
        if @pagy.next
          a(href: library_path(@library, page: @pagy.next),
            class: "px-3 py-2 bg-white border rounded-md hover:bg-gray-50") do
            "Next"
          end
        else
          span(class: "px-3 py-2 text-gray-300 bg-gray-100 border rounded-md cursor-not-allowed") do
            "Next"
          end
        end
      end
    end
  end

end
