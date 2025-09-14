require 'csv'

class LibraryExportService
  def initialize(library)
    @library = library
  end

  def call
    CSV.generate(headers: true) do |csv|
      # Add header row
      csv << [
        'GTIN',
        'Title',
        'Author',
        'Product Type',
        'Publisher',
        'Publication Date',
        'Condition',
        'Location',
        'Acquisition Date',
        'Acquisition Source',
        'Acquisition Price',
        'Notes'
      ]
      
      # Add data rows
      @library.library_items.includes(:product).find_each do |library_item|
        product = library_item.product
        csv << [
          product.gtin,
          product.title,
          product.author,
          product.product_type,
          product.publisher,
          product.publication_date,
          library_item.condition,
          library_item.location,
          library_item.acquisition_date,
          library_item.acquisition_source&.name,
          library_item.acquisition_price,
          library_item.notes
        ]
      end
    end
  end
end