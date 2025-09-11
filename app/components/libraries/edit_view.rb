class Components::Libraries::EditView < Components::Base
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
            form(action: library_path(@library), method: "post") do
              input(type: "hidden", name: "_method", value: "patch")
              input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)

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