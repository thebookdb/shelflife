class Components::Libraries::ShowView < Components::Base
  include ActionView::Helpers::FormTagHelper
  include Phlex::Rails::Helpers::TurboStreamFrom
  include Phlex::Rails::Helpers::LinkTo

  def initialize(library:, products: [], grouped_items: {}, pagy: nil)
    @library = library
    @products = products
    @grouped_items = grouped_items
    @pagy = pagy
  end

  def view_template
    div(class: 'min-h-screen bg-gray-50') do
      render Components::Shared::NavigationView.new

      # Subscribe to library updates — morph refresh on new items or enrichment
      turbo_cable_stream_source(
        channel: 'Turbo::StreamsChannel',
        signed_stream_name: Turbo::StreamsChannel.signed_stream_name("library_#{@library.id}")
      )

      div(class: 'pt-16 px-4', id: 'blahblahblah') do
        div(class: 'max-w-7xl mx-auto') do
          nav(class: 'flex items-center gap-2 text-sm text-gray-600 mb-4') do
            a(href: libraries_path, class: 'hover:text-blue-600 transition-colors') { 'Libraries' }
            span(class: 'text-gray-400') { '/' }
            span(class: 'text-gray-900 font-medium') { @library.name }
          end

          div(class: 'mb-4') do
            div(class: 'flex items-center justify-between') do
              div do
                h1(class: 'text-3xl font-bold text-gray-900') { @library.name }
                p(class: 'text-gray-600 mt-2') { @library.description } if @library.description.present?
              end
            end
          end

          # Pagination at top
          render_pagination if @pagy && @pagy.pages > 1

          # Render grouped products (always present for broadcast target)
          div(class: 'mt-4', id: 'library_products') do
            if @products.any?
              @products.each do |product|
                library_items = @grouped_items[product]
                render Components::Libraries::ProductGroupView.new(
                  product: product,
                  library_items: library_items
                )
              end
            else
              div(class: 'bg-white rounded-lg shadow-md p-8 text-center', id: 'library_empty_state') do
                div(class: 'text-6xl mb-4') { '📚' }
                h2(class: 'text-xl font-semibold text-gray-800 mb-2') { "#{@library.name} is empty" }
                p(class: 'text-gray-600 mb-4') { 'No items have been added to this library yet' }
                a(href: root_path,
                  class: 'bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors') do
                  'Start Scanning'
                end
              end
            end
          end

          # Pagination and action buttons at bottom
          if @products.any?
            div(class: 'mt-8') do
              div(class: 'flex justify-center') do
                render_pagination if @pagy && @pagy.pages > 1
              end

              div(class: 'flex justify-center gap-2 mt-4') do
                a(href: import_library_path(@library),
                  class: 'bg-green-600 text-white px-3 py-1.5 text-sm rounded-lg hover:bg-green-700 transition-colors') do
                  'Import'
                end
                a(href: export_library_path(@library, format: :csv),
                  class: 'bg-purple-600 text-white px-3 py-1.5 text-sm rounded-lg hover:bg-purple-700 transition-colors') do
                  'Export CSV'
                end
                a(href: edit_library_path(@library),
                  class: 'bg-blue-600 text-white px-3 py-1.5 text-sm rounded-lg hover:bg-blue-700 transition-colors') do
                  'Edit Library'
                end
              end
            end
          end
        end
      end
    end
  end

  private

  def render_pagination
    nav(class: 'flex items-center gap-1 text-sm') do
      # Previous link
      if @pagy.prev
        a(href: library_path(@library, page: @pagy.prev),
          class: 'text-blue-600 hover:text-blue-800 hover:underline px-2') do
          '← Previous'
        end
      else
        span(class: 'text-gray-400 px-2') do
          '← Previous'
        end
      end

      span(class: 'text-gray-400 mx-1') { '|' }

      # Page numbers
      start_page = [@pagy.page - 2, 1].max
      end_page = [@pagy.page + 2, @pagy.pages].min

      (start_page..end_page).each do |page_num|
        if page_num == @pagy.page
          span(class: 'font-semibold text-gray-900 px-2') do
            page_num.to_s
          end
        else
          a(href: library_path(@library, page: page_num),
            class: 'text-blue-600 hover:text-blue-800 hover:underline px-2') do
            page_num.to_s
          end
        end
      end

      span(class: 'text-gray-400 mx-1') { '|' }

      # Next link
      if @pagy.next
        a(href: library_path(@library, page: @pagy.next),
          class: 'text-blue-600 hover:text-blue-800 hover:underline px-2') do
          'Next →'
        end
      else
        span(class: 'text-gray-400 px-2') do
          'Next →'
        end
      end
    end
  end
end
