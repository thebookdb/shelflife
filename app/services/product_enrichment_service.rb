class ProductEnrichmentService
  def initialize(tbdb_client: nil)
    @tbdb_client = tbdb_client || Tbdb::Client.new
  end

  def call(product, force = false)
    Rails.logger.info "Enriching product #{product.gtin} from TBDB"

    # Skip if already enriched
    if product.enriched? && force == false
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

  def broadcast_product_update(product)
    # Broadcast to product show page for real-time updates (just the data portion)
    # Create a proper view context for rendering Phlex components
    view_context = ApplicationController.new.view_context
    html = Components::Products::DisplayDataView.new(product: product, libraries: []).render_in(view_context)

    Turbo::StreamsChannel.broadcast_replace_to(
      "product_#{product.id}",
      target: "product-data",
      html: html
    )

    # Broadcast to each library item that contains this product
    product.library_items.find_each do |library_item|
      # Create a proper view context for rendering Phlex components
      view_context = ApplicationController.new.view_context
      html = Components::Libraries::LibraryItemDataView.new(library_item: library_item).render_in(view_context)

      Turbo::StreamsChannel.broadcast_replace_to(
        "library_#{library_item.library_id}",
        target: "library_item_#{library_item.id}",
        html: html
      )
    end
  end

  def fetch_tbdb_data(gtin)
    tbdb_response = @tbdb_client.get_product(gtin)
    return nil unless tbdb_response.present?

    # Extract data from response structure
    tbdb_data = tbdb_response["data"] if tbdb_response.key?("data")
    tbdb_data ||= tbdb_response

    # Verify GTIN matches (TBDB should return exact match)
    if tbdb_data["gtin"] == gtin
      tbdb_data
    else
      Rails.logger.warn "TBDB returned product with different GTIN: expected #{gtin}, got #{tbdb_data["gtin"]}"
      nil
    end
  end

  def update_product_attributes(product, tbdb_data)
    attributes = {}

    # Update basic product info if missing or improve existing
    attributes[:title] = tbdb_data["title"] if tbdb_data["title"].present? && (product.title.blank? || product.title.start_with?("Unknown "))
    attributes[:subtitle] = tbdb_data["subtitle"] if tbdb_data["subtitle"].present?
    attributes[:author] = tbdb_data["author"] if product.author.blank?
    attributes[:publisher] = tbdb_data["publisher"] if product.publisher.blank?
    attributes[:description] = tbdb_data["description"] if product.description.blank?
    attributes[:pages] = tbdb_data["pages"] if product.pages.blank?
    attributes[:genre] = tbdb_data["categories"]&.first if product.genre.blank?

    # Parse publication date
    if product.publication_date.blank? && tbdb_data["publish_date"].present?
      begin
        attributes[:publication_date] = Date.parse(tbdb_data["publish_date"])
      rescue Date::Error
        Rails.logger.warn "Could not parse publication date: #{tbdb_data["publish_date"]}"
      end
    end

    # Store cover image URL (keep for backward compatibility during transition)
    if tbdb_data["cover_url"].present?
      attributes[:cover_image_url] = tbdb_data["cover_url"]
    end

    # Extract format-specific fields from tbdb_data
    if tbdb_data["package"].present?
      case product.product_type
      when "book"
        attributes[:notes] = extract_book_notes(tbdb_data)
      when "video"
        attributes[:notes] = extract_media_notes(tbdb_data)
      when "table_top_game"
        attributes[:notes] = extract_game_notes(tbdb_data)
        attributes[:players] = tbdb_data["players"] if tbdb_data["players"].present?
        attributes[:age_range] = tbdb_data["age_range"] if tbdb_data["age_range"].present?
      end
    end

    # Update the product
    if attributes.any?
      product.update!(attributes)
      # Broadcast the update to all subscribed library items
      broadcast_product_update(product)
    end
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
        content_type: tempfile.content_type || "image/jpeg"
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
    # Broadcast update even for status changes (covers, enrichment status)
    broadcast_product_update(product)
  end

  def extract_filename_from_url(url)
    uri = URI.parse(url)
    File.basename(uri.path) if uri.path.present?
  rescue URI::InvalidURIError
    nil
  end

  def extract_book_notes(tbdb_data)
    notes = []
    notes << "Format: #{tbdb_data["package"]}" if tbdb_data["package"].present?
    notes << "Language: #{tbdb_data.dig("language", "name")}" if tbdb_data.dig("language", "name").present?
    notes << "Region: #{tbdb_data["region"]}" if tbdb_data["region"].present?
    notes.join(" • ")
  end

  def extract_media_notes(tbdb_data)
    notes = []
    notes << "Format: #{tbdb_data["package"]}" if tbdb_data["package"].present?
    notes << "Language: #{tbdb_data.dig("language", "name")}" if tbdb_data.dig("language", "name").present?
    notes << "Region: #{tbdb_data["region"]}" if tbdb_data["region"].present?

    if tbdb_data["duration_seconds"].present?
      duration = format_duration(tbdb_data["duration_seconds"])
      notes << "Duration: #{duration}"
    end

    notes.join(" • ")
  end

  def extract_game_notes(tbdb_data)
    notes = []
    notes << "Language: #{tbdb_data.dig("language", "name")}" if tbdb_data.dig("language", "name").present?
    notes << "Region: #{tbdb_data["region"]}" if tbdb_data["region"].present?
    notes.join(" • ")
  end

  def format_duration(seconds)
    return nil unless seconds

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end
end
