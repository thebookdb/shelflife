class LibrariesController < ApplicationController
  def index
    @libraries = Library.includes(:library_items).all
    render Components::Libraries::IndexView.new(libraries: @libraries)
  end

  def show
    @library = Library.find(params[:id])

    library_items = @library.library_items.includes(:product)

    # Filter out invalid barcodes if user has that setting enabled
    if Current.user.hide_invalid_barcodes?
      library_items = library_items.joins(:product).where(products: { valid_barcode: true })
    end

    # Group library items by product for display
    @grouped_items = library_items.group_by(&:product)

    # Paginate by unique products, not individual items
    products_array = @grouped_items.keys
    @pagy, @products = pagy_array(products_array, overflow: :last_page)

    render Components::Libraries::ShowView.new(
      library: @library,
      products: @products,
      grouped_items: @grouped_items,
      pagy: @pagy
    )
  end

  def edit
    @library = Library.find(params[:id])
    render Components::Libraries::EditView.new(library: @library)
  end

  def update
    @library = Library.find(params[:id])
    
    # Handle bulk barcode input if provided
    bulk_barcodes = params.dig(:library, :bulk_barcodes)
    if bulk_barcodes.present?
      begin
        import_result = process_bulk_barcodes(@library, bulk_barcodes)
        if @library.update(library_params.except(:bulk_barcodes))
          redirect_to library_path(@library), 
                      notice: "Library updated successfully! Added #{import_result[:created]} items, skipped #{import_result[:skipped]} duplicates."
        else
          render Components::Libraries::EditView.new(library: @library), status: :unprocessable_entity
        end
      rescue => e
        @library.errors.add(:bulk_barcodes, "Import failed: #{e.message}")
        render Components::Libraries::EditView.new(library: @library), status: :unprocessable_entity
      end
    else
      if @library.update(library_params)
        redirect_to library_path(@library), notice: "Library updated successfully."
      else
        render Components::Libraries::EditView.new(library: @library), status: :unprocessable_entity
      end
    end
  end

  def import
    @library = Library.find(params[:id])
    
    if request.post?
      file = params[:file]
      
      if file.nil?
        redirect_to import_library_path(@library), alert: "Please select a file to import."
        return
      end

      begin
        import_result = LibraryImportService.new(@library, file, Current.user).call
        
        redirect_to library_path(@library), 
                    notice: "Import completed! Added #{import_result[:created]} items, skipped #{import_result[:skipped]} duplicates."
      rescue => e
        redirect_to import_library_path(@library), alert: "Import failed: #{e.message}"
      end
    else
      render Components::Libraries::ImportView.new(library: @library)
    end
  end

  def export
    @library = Library.find(params[:id])
    
    respond_to do |format|
      format.csv do
        csv_data = LibraryExportService.new(@library).call
        send_data csv_data, 
                  filename: "#{@library.name.parameterize}-#{Date.current}.csv",
                  type: 'text/csv'
      end
    end
  end

  private

  def library_params
    params.expect(library: [:name, :description, :bulk_barcodes])
  end

  def process_bulk_barcodes(library, bulk_barcodes_text)
    gtins = extract_gtins_from_text(bulk_barcodes_text)
    created_count = 0
    skipped_count = 0
    
    gtins.each do |gtin|
      next unless valid_gtin?(gtin)
      
      # Skip if this GTIN already exists in the library
      if library.library_items.joins(:product).exists?(products: { gtin: gtin })
        skipped_count += 1
        next
      end
      
      # Find or create product
      product = find_or_create_product(gtin)
      next unless product
      
      # Create library item
      LibraryItem.create!(
        library: library,
        product: product
      )
      
      # Create scan record for the user
      Scan.create!(
        user: Current.user,
        product: product,
        scanned_at: Time.current
      )
      
      created_count += 1
    end
    
    { created: created_count, skipped: skipped_count }
  end

  def extract_gtins_from_text(text)
    # Extract 13-digit numbers from text (handles space, comma, newline separated)
    text.scan(/\d{13}/).uniq
  end

  def valid_gtin?(gtin)
    gtin.length == 13 && gtin.match?(/^\d{13}$/)
  end

  def find_or_create_product(gtin)
    Product.findd(gtin, title: "Unknown Product (#{gtin})", product_type: 'other')
  end
end
