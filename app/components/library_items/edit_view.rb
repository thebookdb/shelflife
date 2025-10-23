class Components::LibraryItems::EditView < Components::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def initialize(library_item:)
    @library_item = library_item
    @product = library_item.product
    @library = library_item.library
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      render Components::Shared::NavigationView.new

      div(class: "pt-20 px-4") do
        div(class: "max-w-3xl mx-auto") do
          # Header with breadcrumb
          div(class: "mb-6") do
            nav(class: "text-sm text-gray-600 mb-4") do
              a(href: libraries_path, class: "hover:text-blue-600") { "Libraries" }
              plain " / "
              a(href: library_path(@library), class: "hover:text-blue-600") { @library.name }
              plain " / "
              span(class: "text-gray-900") { "Edit Item" }
            end

            h1(class: "text-3xl font-bold text-gray-900") { "Edit Library Item" }
            p(class: "text-gray-600 mt-2") { @product.safe_title }
          end

          div(class: "bg-white rounded-lg shadow-md p-6") do
            # Display errors if any
            if @library_item.errors.any?
              div(class: "mb-6 bg-red-50 border border-red-200 rounded-lg p-4") do
                h3(class: "text-red-800 font-semibold mb-2") { "Error#{@library_item.errors.count > 1 ? 's' : ''}" }
                ul(class: "list-disc list-inside text-red-700 text-sm") do
                  @library_item.errors.full_messages.each do |message|
                    li { message }
                  end
                end
              end
            end

            form(action: library_item_path(@library_item), method: "post") do
              input(type: "hidden", name: "_method", value: "patch")
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

              # Basic Information Section
              div(class: "mb-8") do
                h2(class: "text-lg font-semibold text-gray-800 mb-4 pb-2 border-b") { "Basic Information" }

                div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
                  # Status
                  div do
                    label(for: "library_item_item_status_id", class: "block text-sm font-medium text-gray-700 mb-2") { "Status" }
                    select(
                      id: "library_item_item_status_id",
                      name: "library_item[item_status_id]",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500",
                      data: {
                        controller: "slim-select",
                        slim_select_placeholder_value: "Select status..."
                      }
                    ) do
                      option(value: "", selected: @library_item.item_status_id.nil?) { "Select status..." }
                      ItemStatus.all.each do |status|
                        option(
                          value: status.id,
                          selected: @library_item.item_status_id == status.id
                        ) { status.name }
                      end
                    end
                  end

                  # Ownership Status
                  div do
                    label(for: "library_item_ownership_status_id", class: "block text-sm font-medium text-gray-700 mb-2") { "Ownership" }
                    select(
                      id: "library_item_ownership_status_id",
                      name: "library_item[ownership_status_id]",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500",
                      data: {
                        controller: "slim-select",
                        slim_select_placeholder_value: "Select ownership..."
                      }
                    ) do
                      option(value: "", selected: @library_item.ownership_status_id.nil?) { "Select ownership..." }
                      OwnershipStatus.all.each do |ownership|
                        option(
                          value: ownership.id,
                          selected: @library_item.ownership_status_id == ownership.id
                        ) { ownership.name }
                      end
                    end
                  end

                  # Location
                  div do
                    label(for: "library_item_location", class: "block text-sm font-medium text-gray-700 mb-2") { "Location" }
                    select(
                      id: "library_item_location",
                      name: "library_item[location]",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500",
                      data: {
                        controller: "slim-select",
                        slim_select_allow_create_value: true,
                        slim_select_placeholder_value: "Select or type location..."
                      }
                    ) do
                      option(value: "", selected: @library_item.location.blank?)
                      # Get distinct locations from existing library items
                      LibraryItem.where.not(location: [nil, '']).distinct.pluck(:location).sort.each do |location|
                        option(
                          value: location,
                          selected: @library_item.location == location
                        ) { location }
                      end
                    end
                  end

                  # Copy Identifier
                  div do
                    label(for: "library_item_copy_identifier", class: "block text-sm font-medium text-gray-700 mb-2") { "Copy ID" }
                    input(
                      type: "text",
                      id: "library_item_copy_identifier",
                      name: "library_item[copy_identifier]",
                      value: @library_item.copy_identifier,
                      placeholder: "e.g., Copy 1, First Edition",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    )
                  end
                end
              end

              # Condition Section
              div(class: "mb-8") do
                h2(class: "text-lg font-semibold text-gray-800 mb-4 pb-2 border-b") { "Condition" }

                div(class: "grid grid-cols-1 md:grid-cols-2 gap-4 mb-4") do
                  # Condition
                  div do
                    label(for: "library_item_condition_id", class: "block text-sm font-medium text-gray-700 mb-2") { "Condition" }
                    select(
                      id: "library_item_condition_id",
                      name: "library_item[condition_id]",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500",
                      data: {
                        controller: "slim-select",
                        slim_select_placeholder_value: "Select condition..."
                      }
                    ) do
                      option(value: "", selected: @library_item.condition_id.nil?) { "Not specified" }
                      Condition.all.each do |condition|
                        option(
                          value: condition.id,
                          selected: @library_item.condition_id == condition.id
                        ) { condition.name }
                      end
                    end
                  end
                end

                # Condition Notes
                div do
                  label(for: "library_item_condition_notes", class: "block text-sm font-medium text-gray-700 mb-2") { "Condition Notes" }
                  textarea(
                    id: "library_item_condition_notes",
                    name: "library_item[condition_notes]",
                    rows: "3",
                    placeholder: "Describe any damage, wear, or condition details...",
                    class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  ) { @library_item.condition_notes }
                end
              end

              # Acquisition Section
              div(class: "mb-8") do
                h2(class: "text-lg font-semibold text-gray-800 mb-4 pb-2 border-b") { "Acquisition Details" }

                div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
                  # Acquisition Date
                  div do
                    label(for: "library_item_acquisition_date", class: "block text-sm font-medium text-gray-700 mb-2") { "Date Acquired" }
                    input(
                      type: "date",
                      id: "library_item_acquisition_date",
                      name: "library_item[acquisition_date]",
                      value: @library_item.acquisition_date&.strftime("%Y-%m-%d"),
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    )
                  end

                  # Acquisition Source
                  div do
                    label(for: "library_item_acquisition_source_id", class: "block text-sm font-medium text-gray-700 mb-2") { "Source" }
                    select(
                      id: "library_item_acquisition_source_id",
                      name: "library_item[acquisition_source_id]",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500",
                      data: {
                        controller: "slim-select",
                        slim_select_placeholder_value: "Select source..."
                      }
                    ) do
                      option(value: "", selected: @library_item.acquisition_source_id.nil?) { "Not specified" }
                      AcquisitionSource.all.each do |source|
                        option(
                          value: source.id,
                          selected: @library_item.acquisition_source_id == source.id
                        ) { source.name }
                      end
                    end
                  end

                  # Purchase Price
                  div do
                    label(for: "library_item_acquisition_price", class: "block text-sm font-medium text-gray-700 mb-2") { "Purchase Price" }
                    input(
                      type: "number",
                      step: "0.01",
                      id: "library_item_acquisition_price",
                      name: "library_item[acquisition_price]",
                      value: @library_item.acquisition_price,
                      placeholder: "0.00",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    )
                  end

                  # Original Retail Price
                  div do
                    label(for: "library_item_original_retail_price", class: "block text-sm font-medium text-gray-700 mb-2") { "Original Retail Price" }
                    input(
                      type: "number",
                      step: "0.01",
                      id: "library_item_original_retail_price",
                      name: "library_item[original_retail_price]",
                      value: @library_item.original_retail_price,
                      placeholder: "0.00",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    )
                  end

                  # Replacement Cost
                  div do
                    label(for: "library_item_replacement_cost", class: "block text-sm font-medium text-gray-700 mb-2") { "Replacement Cost" }
                    input(
                      type: "number",
                      step: "0.01",
                      id: "library_item_replacement_cost",
                      name: "library_item[replacement_cost]",
                      value: @library_item.replacement_cost,
                      placeholder: "0.00",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    )
                  end

                  # Current Market Value
                  div do
                    label(for: "library_item_current_market_value", class: "block text-sm font-medium text-gray-700 mb-2") { "Current Market Value" }
                    input(
                      type: "number",
                      step: "0.01",
                      id: "library_item_current_market_value",
                      name: "library_item[current_market_value]",
                      value: @library_item.current_market_value,
                      placeholder: "0.00",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    )
                  end
                end
              end

              # Circulation Section
              div(class: "mb-8") do
                h2(class: "text-lg font-semibold text-gray-800 mb-4 pb-2 border-b") { "Circulation" }

                div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
                  # Lent To
                  div do
                    label(for: "library_item_lent_to", class: "block text-sm font-medium text-gray-700 mb-2") { "Lent To" }
                    input(
                      type: "text",
                      id: "library_item_lent_to",
                      name: "library_item[lent_to]",
                      value: @library_item.lent_to,
                      placeholder: "Person's name",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    )
                  end

                  # Due Date
                  div do
                    label(for: "library_item_due_date", class: "block text-sm font-medium text-gray-700 mb-2") { "Due Date" }
                    input(
                      type: "date",
                      id: "library_item_due_date",
                      name: "library_item[due_date]",
                      value: @library_item.due_date&.strftime("%Y-%m-%d"),
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    )
                  end
                end
              end

              # Notes Section
              div(class: "mb-8") do
                h2(class: "text-lg font-semibold text-gray-800 mb-4 pb-2 border-b") { "Notes" }

                # Public Notes
                div(class: "mb-4") do
                  label(for: "library_item_notes", class: "block text-sm font-medium text-gray-700 mb-2") { "Notes" }
                  textarea(
                    id: "library_item_notes",
                    name: "library_item[notes]",
                    rows: "3",
                    placeholder: "General notes about this copy...",
                    class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  ) { @library_item.notes }
                end

                # Private Notes
                div do
                  label(for: "library_item_private_notes", class: "block text-sm font-medium text-gray-700 mb-2") { "Private Notes" }
                  textarea(
                    id: "library_item_private_notes",
                    name: "library_item[private_notes]",
                    rows: "3",
                    placeholder: "Private notes (not shared)...",
                    class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  ) { @library_item.private_notes }
                end
              end

              # Tags Section
              div(class: "mb-8") do
                h2(class: "text-lg font-semibold text-gray-800 mb-4 pb-2 border-b") { "Tags & Preferences" }

                div(class: "grid grid-cols-1 gap-4") do
                  # Tags
                  div do
                    label(for: "library_item_tags", class: "block text-sm font-medium text-gray-700 mb-2") { "Tags" }
                    input(
                      type: "text",
                      id: "library_item_tags",
                      name: "library_item[tags]",
                      value: @library_item.tags,
                      placeholder: "Comma-separated tags (e.g., favorite, signed, first-edition)",
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    )
                  end

                  # Is Favorite
                  div(class: "flex items-center") do
                    input(
                      type: "checkbox",
                      id: "library_item_is_favorite",
                      name: "library_item[is_favorite]",
                      value: "1",
                      checked: @library_item.is_favorite,
                      class: "h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                    )
                    label(for: "library_item_is_favorite", class: "ml-2 text-sm font-medium text-gray-700") { "Mark as favorite ⭐" }
                  end
                end
              end

              # Action buttons
              div(class: "flex items-center justify-between pt-6 border-t") do
                a(
                  href: library_item_path(@library_item),
                  class: "text-gray-600 hover:text-gray-800"
                ) { "Cancel" }

                button(
                  type: "submit",
                  class: "bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
                ) { "Update Item" }
              end
            end
          end
        end
      end
    end
  end
end
