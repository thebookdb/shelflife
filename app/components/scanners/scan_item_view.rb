class Components::Scanners::ScanItemView < Components::Base
  include ActionView::Helpers::DateHelper
  include ActionView::RecordIdentifier

  def initialize(scan:, template: false)
    @scan = scan
    @template = template
  end

  def view_template
    # Template mode for JavaScript cloning
    if @template
      render_template_item
    elsif @scan
      render_scan_item
    end
  end

  private

  def render_scan_item
    div(
      id: @scan ? dom_id(@scan) : nil,
      class: "p-3 hover:bg-gray-50 transition-colors",
      data: { scan_id: @scan&.id }
    ) do
      div(class: "flex items-center gap-3") do
        # Compact product image
        div(class: "flex-shrink-0") do
          if @scan.product.cover_image.attached?
            img(
              src: url_for(@scan.product.cover_image),
              alt: @scan.product.safe_title,
              class: "w-10 h-12 object-cover rounded"
            )
          elsif @scan.product.cover_image_url.present?
            img(
              src: @scan.product.cover_image_url,
              alt: @scan.product.safe_title,
              class: "w-10 h-12 object-cover rounded"
            )
          else
            div(class: "w-10 h-12 bg-gray-200 rounded flex items-center justify-center") do
              span(class: "text-lg") { product_icon(@scan.product.product_type) }
            end
          end
        end

        # Product details - flex-grow takes remaining space
        div(class: "flex-1 min-w-0") do
          h3(class: "font-medium text-gray-900 text-sm leading-tight truncate") do
            @scan.product.safe_title
          end

          if @scan.product.author.present?
            p(class: "text-xs text-gray-600 truncate") { "by #{@scan.product.author}" }
          end

          # Time and library status
          div(class: "flex items-center justify-between mt-1") do
            span(class: "text-xs text-gray-400") { time_ago_in_words(@scan.scanned_at) }

            # Library status indicator
            if @scan.product.library_items.any?
              libraries = @scan.product.library_items.includes(:library).map(&:library).map(&:name)
              span(class: "text-xs text-green-600 font-medium") do
                "In #{libraries.join(', ')}"
              end
            else
              span(class: "text-xs text-gray-400") { "Not in library" }
            end
          end
        end

        # Quick action button
        div(class: "flex-shrink-0") do
          unless @scan.product.library_items.any?
            button(
              type: "button",
              data_action: "click->barcode-scanner#quickAddToLibrary",
              data_product_id: @scan.product.id,
              class: "bg-green-100 hover:bg-green-200 text-green-700 text-xs px-2 py-1 rounded-md font-medium transition-colors"
            ) { "Add" }
          else
            span(class: "text-green-600 text-xs") { "✓" }
          end
        end
      end
    end
  end

  def render_template_item
    # Template for JavaScript to clone and populate
    div(
      class: "p-3 hover:bg-gray-50 transition-colors",
      data: { template: "scan-item" }
    ) do
      div(class: "flex items-center gap-3") do
        # Product image placeholder
        div(class: "flex-shrink-0") do
          div(class: "w-10 h-12 bg-gray-200 rounded flex items-center justify-center") do
            span(class: "text-lg", data: { template_field: "icon" }) { "📚" }
          end
        end

        # Product details
        div(class: "flex-1 min-w-0") do
          h3(class: "font-medium text-gray-900 text-sm leading-tight truncate") do
            span(data: { template_field: "title" }) { "Loading..." }
          end

          p(class: "text-xs text-gray-600 truncate") do
            span(data: { template_field: "author" }) { "" }
          end

          div(class: "flex items-center justify-between mt-1") do
            span(class: "text-xs text-gray-400") { "Just now" }
            span(class: "text-xs text-gray-400", data: { template_field: "status" }) { "Checking..." }
          end
        end

        # Quick action button
        div(class: "flex-shrink-0") do
          button(
            type: "button",
            data_action: "click->barcode-scanner#quickAddToLibrary",
            data: { template_field: "add_button" },
            class: "bg-green-100 hover:bg-green-200 text-green-700 text-xs px-2 py-1 rounded-md font-medium transition-colors"
          ) { "Add" }
        end
      end
    end
  end

  def product_icon(product_type)
    case product_type
    when "book" then "📚"
    when "video" then "💿"
    when "ebook" then "📱"
    when "audiobook" then "🎧"
    when "toy" then "🧸"
    when "lego" then "🧱"
    when "pop" then "🎭"
    when "graphic_novel" then "📖"
    when "box_set" then "📦"
    when "music" then "🎵"
    when "ereader" then "📖"
    when "table_top_game" then "🎲"
    else "📦"
    end
  end

  def time_ago_in_words(time)
    return "Just now" unless time

    diff = Time.current - time
    case diff
    when 0..59
      "#{diff.to_i}s ago"
    when 60..3599
      "#{(diff / 60).to_i}m ago"
    when 3600..86399
      "#{(diff / 3600).to_i}h ago"
    else
      "#{(diff / 86400).to_i}d ago"
    end
  end
end
