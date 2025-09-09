class ProductEnrichmentService
  def initialize(tbdb_service: nil, user: nil)
    @tbdb_service = tbdb_service || ShelfLife::TbdbService.new(user: user)
  end

  def call(product)
    Rails.logger.info "Enriching product #{product.gtin} from TBDB"

    # Skip if already enriched
    if product.enriched?
      Rails.logger.debug "Product #{product.gtin} already has TBDB data, skipping"
      return product
    end

    begin
      tbdb_data = fetch_tbdb_data(product.gtin)

      if tbdb_data.present?
        update_product_attributes(product, tbdb_data)
        attach_cover_image(product, tbdb_data["cover_url"]) if tbdb_data["cover_url"].present?
        mark_enrichment_status(product, "success", tbdb_data)
        Rails.logger.info "Successfully enriched product #{product.gtin} with TBDB data"
      else
        mark_enrichment_status(product, "not_found", "Product not found in TBDB database")
        Rails.logger.info "Product #{product.gtin} not found in TBDB database"
      end

      product

    rescue => e
      Rails.logger.error "Error enriching product #{product.gtin}: #{e.message}"
      mark_enrichment_status(product, "error", e.message)
      raise e # Re-raise to trigger job retry mechanism
    end
  end

  private

  def fetch_tbdb_data(gtin)
    tbdb_response = @tbdb_service.get_product(gtin)
    return nil unless tbdb_response.present?

    # Extract data from response structure
    tbdb_data = tbdb_response["data"] if tbdb_response.key?("data")
    tbdb_data ||= tbdb_response

    # Verify GTIN matches (TBDB should return exact match)
    if tbdb_data["gtin"] == gtin
      tbdb_data
    else
      Rails.logger.warn "TBDB returned product with different GTIN: expected #{gtin}, got #{tbdb_data['gtin']}"
      nil
    end
  end

  def update_product_attributes(product, tbdb_data)
    attributes = {}

    # Update basic product info if missing or improve existing
    attributes[:title] = tbdb_data["title"] if tbdb_data["title"].present? && (product.title.blank? || product.title.start_with?("Product "))
    attributes[:subtitle] = tbdb_data["subtitle"] if tbdb_data["subtitle"].present?
    attributes[:author] = tbdb_data["authors"]&.first&.dig("name") if product.author.blank?
    attributes[:publisher] = tbdb_data["publisher"] if product.publisher.blank?
    attributes[:description] = tbdb_data["description"] if product.description.blank?
    attributes[:pages] = tbdb_data["pages"] if product.pages.blank?
    attributes[:genre] = tbdb_data["categories"]&.first if product.genre.blank?

    # Parse publication date
    if product.publication_date.blank? && tbdb_data["publish_date"].present?
      begin
        attributes[:publication_date] = Date.parse(tbdb_data["publish_date"])
      rescue Date::Error
        Rails.logger.warn "Could not parse publication date: #{tbdb_data['publish_date']}"
      end
    end

    # Store cover image URL (keep for backward compatibility during transition)
    if tbdb_data["cover_url"].present?
      attributes[:cover_image_url] = tbdb_data["cover_url"]
    end

    # Update the product
    product.update!(attributes) if attributes.any?
  end

  def attach_cover_image(product, cover_url)
    return if product.cover_image.attached? # Don't overwrite existing image

    begin
      Rails.logger.info "Downloading cover image for product #{product.gtin} from #{cover_url}"

      # Download the image using Down gem (handles redirects, proper headers, etc.)
      tempfile = Down.download(cover_url)
      
      # Extract filename from URL or generate one
      filename = extract_filename_from_url(cover_url) || "cover_#{product.gtin}.jpg"

      # Attach the image
      product.cover_image.attach(
        io: tempfile,
        filename: filename,
        content_type: tempfile.content_type || 'image/jpeg'
      )

      Rails.logger.info "Successfully attached cover image for product #{product.gtin}"

    rescue => e
      Rails.logger.error "Failed to download cover image for product #{product.gtin}: #{e.message}"
      # Don't re-raise - cover image failure shouldn't fail the whole enrichment
    end
  end

  def mark_enrichment_status(product, status, data)
    tbdb_data = {
      fetched_at: Time.current.iso8601,
      status: status
    }

    case status
    when "success"
      tbdb_data[:data] = data
    when "error"
      tbdb_data[:error] = data
    when "not_found"
      tbdb_data[:message] = data
    end

    product.update!(tbdb_data: tbdb_data)
  end

  def extract_filename_from_url(url)
    uri = URI.parse(url)
    File.basename(uri.path) if uri.path.present?
  rescue URI::InvalidURIError
    nil
  end
end
