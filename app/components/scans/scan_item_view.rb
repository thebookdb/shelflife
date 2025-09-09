module Components
  module Scans
    class ScanItemView < Phlex::HTML
      include ActionView::Helpers::DateHelper
      include ActionView::RecordIdentifier
      include Phlex::Rails::Helpers::URLFor

      def initialize(scan:)
        @scan = scan
      end

      def view_template
        div(id: dom_id(@scan), class: "bg-white rounded-lg shadow-md p-4 flex items-center space-x-4") do
          # Product image or placeholder
          div(class: "flex-shrink-0") do
            if @scan.product.cover_image.attached?
              img(
                src: url_for(@scan.product.cover_image),
                alt: @scan.product.safe_title,
                class: "w-16 h-20 object-cover rounded"
              )
            elsif @scan.product.cover_image_url.present?
              # Fallback to URL during transition period
              img(
                src: @scan.product.cover_image_url,
                alt: @scan.product.safe_title,
                class: "w-16 h-20 object-cover rounded"
              )
            else
              div(class: "w-16 h-20 bg-gray-200 rounded flex items-center justify-center") do
                span(class: "text-2xl") { "📚" }
              end
            end
          end

          # Product details
          div(class: "flex-grow") do
            h3(class: "font-semibold text-gray-900") do
              a(href: "/#{@scan.product.gtin}", class: "hover:text-blue-600") do
                @scan.product.safe_title
              end
            end

            if @scan.product.author.present?
              p(class: "text-sm text-gray-600") { "by #{@scan.product.author}" }
            end

            p(class: "text-xs text-gray-500 mt-1") do
              "GTIN: #{@scan.product.gtin}"
            end

            if @scan.user.present?
              p(class: "text-xs text-gray-400 mt-1") do
                "Scanned by #{@scan.user.email_address}"
              end
            end
          end

          # Scan time
          div(class: "flex-shrink-0 text-right") do
            p(class: "text-sm text-gray-500") do
              time_ago_in_words(@scan.scanned_at)
            end
            p(class: "text-xs text-gray-400") do
              @scan.scanned_at.strftime("%b %d, %Y")
            end
          end
        end
      end

      private

      def time_ago_in_words(time)
        # Simple time ago implementation
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
  end
end
