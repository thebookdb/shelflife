class Components::Scanners::IndexView < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(recent_items:, libraries:)
    @recent_items = recent_items
    @libraries = libraries
  end

  def view_template
    style do
      raw(<<~CSS.html_safe)
        /* Video fills scanner container */
        #portrait-scanner video, #landscape-scanner video {
          width: 100% !important;
          height: 100% !important;
          object-fit: cover !important;
          position: absolute !important;
          top: 0 !important;
          left: 0 !important;
        }
        #portrait-scanner, #landscape-scanner {
          background: transparent !important;
          border: none !important;
          padding: 0 !important;
          width: 100% !important;
          height: 100% !important;
          overflow: hidden !important;
        }
      CSS
    end

    div(
      class: "fixed inset-0 top-28 bg-gray-900 flex flex-col",
      data_controller: "barcode-scanner"
    ) do
      # Camera area — fills available space
      div(class: "flex-1 relative overflow-hidden") do
        # Portrait scanner element (hidden until scanning)
        div(
          id: "portrait-scanner",
          data_barcode_scanner_target: "portraitScanner",
          class: "hidden absolute inset-0"
        )

        # Landscape scanner element (hidden until scanning)
        div(
          id: "landscape-scanner",
          data_barcode_scanner_target: "landscapeScanner",
          class: "hidden absolute inset-0"
        )

        # Placeholder — shown before scanning starts
        div(
          data_barcode_scanner_target: "portraitPlaceholder landscapePlaceholder",
          class: "absolute inset-0 flex flex-col items-center justify-center"
        ) do
          # Viewfinder frame
          div(class: "relative w-64 h-44 mb-6") do
            # Corner brackets
            div(class: "absolute top-0 left-0 w-8 h-8 border-t-4 border-l-4 border-white rounded-tl-lg")
            div(class: "absolute top-0 right-0 w-8 h-8 border-t-4 border-r-4 border-white rounded-tr-lg")
            div(class: "absolute bottom-0 left-0 w-8 h-8 border-b-4 border-l-4 border-white rounded-bl-lg")
            div(class: "absolute bottom-0 right-0 w-8 h-8 border-b-4 border-r-4 border-white rounded-br-lg")
            div(class: "absolute inset-0 flex items-center justify-center") do
              span(class: "text-white/30 text-5xl") { "▬" }
            end
          end
          p(class: "text-white/60 text-sm") { "Point camera at a barcode" }
        end

        # Scanning overlay — stop button (hidden until scanning)
        div(class: "absolute bottom-6 left-0 right-0 z-20 flex justify-center hidden",
            data_barcode_scanner_target: "scanResult") do
          button(
            type: "button",
            data_action: "click->barcode-scanner#stopScanning",
            data_barcode_scanner_target: "stopButton",
            class: "bg-red-600 text-white px-8 py-3 rounded-xl font-semibold shadow-lg text-base"
          ) { "Stop" }
        end

        # Hidden orientation display (used by JS)
        div(
          data_barcode_scanner_target: "orientationDisplay",
          class: "hidden"
        )
      end

      # Control panel — white card at bottom
      div(class: "bg-white px-4 pt-4 pb-6 flex flex-col gap-3 shadow-[0_-4px_16px_rgba(0,0,0,0.15)]") do
        button(
          type: "button",
          data_action: "click->barcode-scanner#startScanning",
          data_barcode_scanner_target: "startButton",
          class: "w-full bg-green-600 text-white py-4 rounded-xl font-semibold text-lg shadow flex items-center justify-center gap-2 active:bg-green-700"
        ) do
          span { "📷" }
          span { "Start Scanning" }
        end

        # Last scan result — populated via turbo stream on successful scan
        div(id: "scanner-last-scan")

        div(data_barcode_scanner_target: "libraryStatus") do
          label(class: "text-xs font-medium text-gray-400 uppercase tracking-wide block mb-1") { "Scanning into" }
          select(
            data_barcode_scanner_target: "librarySelect",
            class: "w-full bg-gray-50 border border-gray-200 rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800"
          ) do
            @libraries.each do |library|
              option(value: library.id, selected: Current.library&.id == library.id) { library.name }
            end
          end
        end

        if @recent_items.any?
          div do
            p(class: "text-xs font-medium text-gray-400 uppercase tracking-wide mb-1.5") { "Recent" }
            div(class: "space-y-1") do
              @recent_items.first(3).each do |item|
                div(class: "flex items-center gap-2 py-1") do
                  span(class: "text-xs text-gray-400 flex-shrink-0") { item.date_added.strftime("%H:%M") }
                  span(class: "text-sm text-gray-700 truncate") do
                    item.product&.title || item.product&.gtin || "Unknown"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
