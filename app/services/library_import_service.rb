require 'csv'

class LibraryImportService
  def initialize(library, file, user)
    @library = library
    @file = file
    @user = user
  end

  def call
    gtins = extract_gtins_from_file
    created_count = 0
    skipped_count = 0
    
    gtins.each do |gtin|
      next unless valid_gtin?(gtin)
      
      # Skip if this GTIN already exists in the library
      if library_item_exists?(gtin)
        skipped_count += 1
        next
      end
      
      # Find or create product
      product = find_or_create_product(gtin)
      next unless product
      
      # Create library item
      LibraryItem.create!(
        library: @library,
        product: product,
      )
      
      # Create scan record for the user
      Scan.create!(
        user: @user,
        product: product,
        scanned_at: Time.current
      )
      
      created_count += 1
    end
    
    { created: created_count, skipped: skipped_count }
  end
  
  private
  
  def extract_gtins_from_file
    content = @file.read.force_encoding('UTF-8')
    gtins = []
    
    # Try to parse as CSV first
    begin
      CSV.parse(content, headers: false) do |row|
        row.each do |cell|
          next unless cell
          # Extract 13-digit numbers from the cell
          cell.to_s.scan(/\d{13}/).each { |gtin| gtins << gtin }
        end
      end
    rescue CSV::MalformedCSVError
      # If CSV parsing fails, treat as plain text
      gtins = content.scan(/\d{13}/)
    end
    
    gtins.uniq
  end
  
  def valid_gtin?(gtin)
    gtin.length == 13 && gtin.match?(/^\d{13}$/)
  end
  
  def library_item_exists?(gtin)
    @library.library_items.joins(:product).exists?(products: { gtin: gtin })
  end
  
  def find_or_create_product(gtin)
    product = Product.find_by(gtin: gtin)
    return product if product
    
    # Create new product with minimal data
    Product.create!(
      gtin: gtin,
      title: "Unknown Product (#{gtin})",
      product_type: 'other'
    )
  end
end