class Components::Libraries::ImportView < Components::Base
  def initialize(library:)
    @library = library
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      render Components::Shared::NavigationView.new

      div(class: "pt-20 px-4") do
        div(class: "max-w-2xl mx-auto") do
          div(class: "mb-8") do
            h1(class: "text-3xl font-bold text-gray-900 mb-2") { "Import Items to #{@library.name}" }
            p(class: "text-gray-600") { "Upload a CSV or text file containing GTINs to add items to your library" }
          end

          div(class: "bg-white rounded-lg shadow-md p-6") do
            form_with url: import_library_path(@library), method: :post, multipart: true, class: "space-y-6" do |form|
              div do
                label(for: "file", class: "block text-sm font-medium text-gray-700 mb-2") { "Select File" }
                input(
                  type: "file",
                  name: "file",
                  id: "file",
                  accept: ".csv,.txt",
                  required: true,
                  class: "block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
                )
                p(class: "mt-2 text-sm text-gray-500") { "Accepts CSV and TXT files with GTINs (13-digit barcodes)" }
              end

              div(class: "bg-blue-50 p-4 rounded-lg") do
                h3(class: "text-sm font-medium text-blue-900 mb-2") { "File Format Guidelines" }
                ul(class: "text-sm text-blue-800 space-y-1") do
                  li { "• CSV files: GTINs can be in any column" }
                  li { "• Text files: One GTIN per line or space/comma separated" }
                  li { "• GTINs must be exactly 13 digits" }
                  li { "• Duplicate GTINs within this library will be skipped" }
                end
              end

              div(class: "flex justify-between") do
                a(
                  href: library_path(@library),
                  class: "px-4 py-2 text-gray-700 bg-gray-200 rounded-lg hover:bg-gray-300 transition-colors"
                ) { "Cancel" }
                
                button(
                  type: "submit",
                  class: "px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                ) { "Import Items" }
              end
            end
          end

          div(class: "mt-8 bg-white rounded-lg shadow-md p-6") do
            h3(class: "text-lg font-semibold text-gray-900 mb-4") { "Sample File Formats" }
            
            div(class: "space-y-4") do
              div do
                h4(class: "text-sm font-medium text-gray-700 mb-2") { "CSV Format:" }
                pre(class: "bg-gray-100 p-3 rounded text-sm overflow-x-auto") do
                  plain <<~CSV
                    Title,GTIN,Author
                    "Example Book",9780123456789,"John Doe"
                    "Another Item",9780987654321,"Jane Smith"
                  CSV
                end
              end
              
              div do
                h4(class: "text-sm font-medium text-gray-700 mb-2") { "Text Format:" }
                pre(class: "bg-gray-100 p-3 rounded text-sm overflow-x-auto") do
                  plain <<~TXT
                    9780123456789
                    9780987654321
                    9781234567890
                  TXT
                end
              end
            end
          end
        end
      end
    end
  end
end