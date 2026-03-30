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
              a(href: libraries_path, class: "hover:text-orange-600") { "Libraries" }
              plain " / "
              a(href: library_path(@library), class: "hover:text-orange-600") { @library.name }
              plain " / "
              a(href: library_item_path(@library_item), class: "hover:text-orange-600") { @product.safe_title }
              plain " / "
              span(class: "text-gray-900 font-medium") { "Edit" }
            end

            h1(class: "text-3xl font-bold text-gray-900") { "Edit Your Copy" }
          end

          div(class: "bg-orange-50 rounded-lg shadow-md p-6 border-l-4 #{intent_border_class(@library_item)} relative") do
            # Display errors if any
            if @library_item.errors.any?
              div(class: "mb-6 bg-red-50 border border-red-200 rounded-lg p-4") do
                h3(class: "text-red-800 font-semibold mb-2") { "Error#{"s" if @library_item.errors.count > 1}" }
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

              # Favourite toggle - top right
              div(class: "absolute top-4 right-4") do
                label(for: "library_item_is_favorite", class: "flex items-center gap-1.5 cursor-pointer select-none") do
                  input(
                    type: "checkbox",
                    id: "library_item_is_favorite",
                    name: "library_item[is_favorite]",
                    value: "1",
                    checked: @library_item.is_favorite,
                    class: "hidden peer"
                  )
                  star_class = @library_item.is_favorite ? "text-2xl peer-checked:scale-110 transition-transform" : "text-2xl peer-checked:scale-110 transition-transform opacity-40 grayscale"
                  span(class: star_class) { "⭐" }
                  span(class: "text-xs font-medium text-gray-500") { "Trophy" }
                end
              end

              div(class: "mb-8") do
                # Basic Information Section
                div(class: "mb-8") do
                  h2(class: "text-lg font-semibold text-orange-700 mb-4 pb-2 border-b border-orange-200") { "Basic Information" }

                  div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
                    div do
                      label(for: "library_item_intent", class: "block text-sm font-medium text-gray-700 mb-2") { "Intent" }
                      select(
                        id: "library_item_intent",
                        name: "library_item[intent]",
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
                      ) do
                        option(value: "have", selected: @library_item.have?) { "Have" }
                        option(value: "want", selected: @library_item.want?) { "Want" }
                      end
                    end

                    # Status
                    div do
                      label(for: "library_item_item_status_id", class: "block text-sm font-medium text-gray-700 mb-2") { "Status" }
                      select(
                        id: "library_item_item_status_id",
                        name: "library_item[item_status_id]",
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500",
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
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500",
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
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500",
                        data: {
                          controller: "slim-select",
                          slim_select_allow_create_value: true,
                          slim_select_placeholder_value: "Select or type location..."
                        }
                      ) do
                        option(value: "", selected: @library_item.location.blank?)
                        # Get distinct locations from existing library items
                        LibraryItem.where.not(location: [nil, ""]).distinct.pluck(:location).sort.each do |location|
                          option(
                            value: location,
                            selected: @library_item.location == location
                          ) { location }
                        end
                      end
                    end

                    # Genre (on product)
                    div do
                      label(for: "product_genre", class: "block text-sm font-medium text-gray-700 mb-2") { "Genre" }
                      select(
                        id: "product_genre",
                        name: "product[genre]",
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500",
                        data: {
                          controller: "slim-select",
                          slim_select_allow_create_value: true,
                          slim_select_placeholder_value: "Select or type genre..."
                        }
                      ) do
                        option(value: "", selected: @product.genre.blank?)
                        Product.where.not(genre: [nil, ""]).distinct.pluck(:genre).sort.each do |genre|
                          option(value: genre, selected: @product.genre == genre) { genre }
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
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
                      )
                    end
                  end
                end

                # Condition Section
                div(class: "mb-8") do
                  h2(class: "text-lg font-semibold text-orange-700 mb-4 pb-2 border-b border-orange-200") { "Condition" }

                  div(class: "grid grid-cols-1 md:grid-cols-2 gap-4 mb-4") do
                    # Condition
                    div do
                      label(for: "library_item_condition_id", class: "block text-sm font-medium text-gray-700 mb-2") { "Condition" }
                      select(
                        id: "library_item_condition_id",
                        name: "library_item[condition_id]",
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500",
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
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
                    ) { @library_item.condition_notes }
                  end
                end

                # Acquisition Section
                div(class: "mb-8") do
                  h2(class: "text-lg font-semibold text-orange-700 mb-4 pb-2 border-b border-orange-200") { "Acquisition Details" }

                  div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
                    # Acquisition Date
                    div do
                      label(for: "library_item_acquisition_date", class: "block text-sm font-medium text-gray-700 mb-2") { "Date Acquired" }
                      input(
                        type: "date",
                        id: "library_item_acquisition_date",
                        name: "library_item[acquisition_date]",
                        value: @library_item.acquisition_date&.strftime("%Y-%m-%d"),
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
                      )
                    end

                    # Acquisition Source
                    div do
                      label(for: "library_item_acquisition_source_id", class: "block text-sm font-medium text-gray-700 mb-2") { "Source" }
                      select(
                        id: "library_item_acquisition_source_id",
                        name: "library_item[acquisition_source_id]",
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500",
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
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
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
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
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
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
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
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
                      )
                    end
                  end
                end
              end

              # Notes Section
              div(class: "mb-8") do
                h2(class: "text-lg font-semibold text-orange-700 mb-4 pb-2 border-b border-orange-200") { "Notes" }

                # Public Notes
                div(class: "mb-4") do
                  label(for: "library_item_notes", class: "block text-sm font-medium text-gray-700 mb-2") { "Notes" }
                  textarea(
                    id: "library_item_notes",
                    name: "library_item[notes]",
                    rows: "3",
                    placeholder: "General notes about this copy...",
                    class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
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
                    class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
                  ) { @library_item.private_notes }
                end
              end

              # Tags Section
              div(class: "mb-8") do
                h2(class: "text-lg font-semibold text-orange-700 mb-4 pb-2 border-b border-orange-200") { "Tags & Preferences" }

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
                      class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-orange-500 focus:border-orange-500"
                    )
                  end
                end
              end

              # Action buttons
              div(class: "flex items-center justify-between pt-6 border-t border-orange-200") do
                a(
                  href: library_item_path(@library_item),
                  class: "text-gray-600 hover:text-gray-800"
                ) { "Cancel" }

                button(
                  type: "submit",
                  class: "#{@library_item.have? ? "bg-orange-600 hover:bg-orange-700" : "bg-slate-600 hover:bg-slate-700"} text-white px-6 py-2 rounded-lg transition-colors"
                ) { "Update Item" }
              end
            end
          end
        end
      end
    end
  end
end
