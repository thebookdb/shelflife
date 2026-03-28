class Components::Products::NewView < Components::Base
  PRODUCT_TYPES = %w[book video ebook audiobook toy lego pop graphic_novel box_set music ereader table_top_game other].freeze

  def initialize(gtin: "", error: nil)
    @gtin = gtin
    @error = error
  end

  def view_template
    div(class: "min-h-screen bg-gray-50 pt-8") do
      div(class: "max-w-lg mx-auto px-4 py-8") do
        h1(class: "text-3xl font-bold text-gray-900 mb-2") { "Add Item by Barcode" }
        p(class: "text-gray-500 mb-8") { "Enter a 13-digit barcode to look up or create a product." }

        if @error
          div(class: "mb-6 bg-red-50 border border-red-200 rounded-lg p-4 text-red-700 text-sm") { @error }
        end

        form_with(url: products_path, method: :post, local: true, class: "bg-white rounded-xl shadow-sm border border-gray-100 p-6 space-y-5") do |f|
          div do
            label(for: "gtin", class: "block text-sm font-medium text-gray-700 mb-1") { "Barcode (EAN-13)" }
            input(
              type: "text",
              id: "gtin",
              name: "gtin",
              value: @gtin,
              placeholder: "e.g. 9780143058144",
              maxlength: "13",
              pattern: "\\d{13}",
              required: true,
              autofocus: true,
              class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 font-mono text-lg tracking-widest"
            )
          end

          div do
            label(for: "product_type", class: "block text-sm font-medium text-gray-700 mb-1") { "Type" }
            select(
              id: "product_type",
              name: "product_type",
              class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
            ) do
              PRODUCT_TYPES.each do |type|
                option(value: type, selected: type == "book") { type.humanize }
              end
            end
          end

          f.button(
            type: "submit",
            class: "w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-3 rounded-lg transition-colors"
          ) { "Find or Create Item" }
        end
      end
    end
  end
end
