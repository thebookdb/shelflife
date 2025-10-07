class Components::Libraries::EditView < Components::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken
  def initialize(library:)
    @library = library
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      render Components::Shared::NavigationView.new

      div(class: "pt-20 px-4") do
        div(class: "max-w-2xl mx-auto") do
          div(class: "mb-8") do
            h1(class: "text-3xl font-bold text-gray-900") { "Edit Library" }
            p(class: "text-gray-600 mt-2") { "Update the name and description for this library" }
          end

          div(class: "bg-white rounded-lg shadow-md p-6") do
            # Display errors if any
            if @library.errors.any?
              div(class: "mb-6 bg-red-50 border border-red-200 rounded-lg p-4") do
                h3(class: "text-red-800 font-semibold mb-2") { "Error#{@library.errors.count > 1 ? 's' : ''}" }
                ul(class: "list-disc list-inside text-red-700 text-sm") do
                  @library.errors.full_messages.each do |message|
                    li { message }
                  end
                end
              end
            end

            form(action: library_path(@library), method: "post") do
              input(type: "hidden", name: "_method", value: "patch")
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

              # Library name field
              div(class: "mb-6") do
                label(for: "library_name", class: "block text-sm font-medium text-gray-700 mb-2") { "Library Name" }
                input(
                  type: "text",
                  id: "library_name",
                  name: "library[name]",
                  value: @library.name,
                  required: true,
                  class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                )
              end

              # Library description field
              div(class: "mb-6") do
                label(for: "library_description", class: "block text-sm font-medium text-gray-700 mb-2") { "Description" }
                textarea(
                  id: "library_description",
                  name: "library[description]",
                  rows: "4",
                  class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500",
                  placeholder: "Enter a description for this library (optional)"
                ) { @library.description }
              end

              # Bulk barcodes field
              div(class: "mb-6") do
                label(for: "library_bulk_barcodes", class: "block text-sm font-medium text-gray-700 mb-2") { "Add Items by Barcode" }
                textarea(
                  id: "library_bulk_barcodes",
                  name: "library[bulk_barcodes]",
                  rows: "6",
                  class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500",
                  placeholder: "Paste GTINs here (one per line, space separated, or comma separated)..."
                )
                p(class: "mt-2 text-sm text-gray-500") do
                  plain "Paste 13-digit barcodes to add items to this library. "
                  plain "Example: 9780123456789, 9781234567890"
                end
              end

              # Action buttons
              div(class: "flex items-center justify-between") do
                a(
                  href: library_path(@library),
                  class: "text-gray-600 hover:text-gray-800"
                ) { "Cancel" }

                button(
                  type: "submit",
                  class: "bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
                ) { "Update Library" }
              end
            end
          end
        end
      end
    end
  end
end
