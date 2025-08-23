class Components::Scanners::HorizontalView < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(recent_scans:, libraries:)
    @recent_scans = recent_scans
    @libraries = libraries
  end

  def view_template
    # CSS for html5-qrcode styling in horizontal layout
    style do
      raw(<<~CSS.html_safe)
        #horizontal-scanner {
          background-color: #1f2937 !important;
          padding: 10px !important;
        }
        #horizontal-scanner div {
          color: white !important;
          margin-bottom: 8px !important;
        }
        #horizontal-scanner button {
          background-color: #374151 !important;
          color: white !important;
          border: 1px solid #6b7280 !important;
          margin: 4px !important;
          padding: 8px 12px !important;
          border-radius: 6px !important;
        }
        #horizontal-scanner a {
          color: #60a5fa !important;
          display: block !important;
          margin: 8px 0 !important;
        }
        #horizontal-scanner select {
          background-color: #374151 !important;
          color: white !important;
          border: 1px solid #6b7280 !important;
          margin: 4px !important;
          padding: 6px !important;
          border-radius: 4px !important;
          min-width: 150px !important;
        }
        #horizontal-scanner input {
          background-color: #374151 !important;
          color: white !important;
          border: 1px solid #6b7280 !important;
          margin: 4px !important;
          padding: 6px !important;
          border-radius: 4px !important;
        }
        /* Specific html5-qrcode element styling for horizontal layout */
        #horizontal-scanner .qr-shaded-region {
          background-color: rgba(0, 0, 0, 0.5) !important;
        }
        #horizontal-scanner .qr-scanner-ui {
          margin: 10px 0 !important;
        }
        #horizontal-scanner .qr-scanner-ui > div {
          margin: 6px 0 !important;
        }
        /* Style the camera selection and torch controls for horizontal */
        #horizontal-scanner div[style*="display: flex"] {
          flex-wrap: wrap !important;
          gap: 8px !important;
          justify-content: center !important;
          align-items: center !important;
        }
        /* Ensure html5-qrcode UI doesn't overflow the scanner area */
        #horizontal-scanner > div {
          max-height: 100% !important;
          overflow-y: auto !important;
        }
        /* Position camera controls at the bottom right for horizontal */
        #horizontal-scanner .qr-scanner-ui {
          position: absolute !important;
          bottom: 10px !important;
          right: 10px !important;
          background-color: rgba(31, 41, 55, 0.9) !important;
          padding: 8px !important;
          border-radius: 8px !important;
          max-width: 200px !important;
        }
      CSS
    end

    # Horizontal-first scanner layout - break out of main container
    div(
      class: "fixed inset-0 top-16 bg-gray-50 overflow-hidden",
      data_controller: "horizontal-barcode-scanner",
      data_horizontal_barcode_scanner_scanner_page_value: "true"
    ) do
      div(class: "h-full flex") do
        # Scanner Area - Takes up 70% of width for horizontal scanning
        div(class: "flex-none w-[70%] bg-black relative") do
          # Floating controls - positioned at top for horizontal
          div(class: "absolute top-4 left-4 right-4 z-20 flex justify-between items-center") do
            # Stop button on the left
            button(
              type: "button",
              data_action: "click->horizontal-barcode-scanner#stopScanning",
              data_horizontal_barcode_scanner_target: "stopButton",
              class: "bg-red-600 text-white px-3 py-2 rounded-lg hover:bg-red-700 transition-colors font-medium shadow-lg hidden flex items-center gap-2"
            ) do
              span(class: "text-lg") { "⏹" }
              span(class: "text-sm") { "Stop" }
            end

            # Scan result display on the right
            div(
              data_horizontal_barcode_scanner_target: "scanResult",
              class: "bg-gray-800/90 backdrop-blur-sm text-white px-3 py-2 rounded-lg hidden"
            ) do
              p(data_horizontal_barcode_scanner_target: "result", class: "font-mono text-sm text-white")
            end
          end

          # Scanner container
          div(
            id: "horizontal-scanner",
            data_horizontal_barcode_scanner_target: "scanner",
            class: "w-full h-full relative z-10"
          )

          # Placeholder when not scanning
          div(
            data_horizontal_barcode_scanner_target: "placeholder",
            class: "absolute inset-0 flex items-center justify-center text-white"
          ) do
            div(class: "text-center") do
              div(class: "text-8xl mb-4") { "📷" }
              p(class: "text-xl mb-2") { "Scanner" }
              p(class: "text-lg opacity-75") { "Optimized for landscape mode" }
              p(class: "text-sm opacity-50 mt-4") { "Camera will appear here when scanning starts" }
            end
          end
        end

        # Control Panel - Right side 30% of screen
        div(class: "flex-1 bg-white border-l border-gray-200 overflow-y-auto") do
          div(class: "p-6 h-full flex flex-col") do
            # Header
            div(class: "mb-6") do
              h2(class: "text-2xl font-bold text-gray-800 mb-2") { "Scanner" }
              p(class: "text-sm text-gray-600") { "Hold device horizontally for best results" }
            end

            # Start/Status Section
            div(class: "mb-6") do
              # Start button
              button(
                type: "button",
                data_action: "click->horizontal-barcode-scanner#startScanning",
                data_horizontal_barcode_scanner_target: "startButton",
                class: "w-full bg-green-600 text-white py-4 px-6 rounded-lg hover:bg-green-700 transition-colors font-medium shadow-lg flex items-center justify-center gap-3 mb-4"
              ) do
                span(class: "text-2xl") { "📱" }
                span(class: "text-lg") { "Scan" }
              end

              # Scanning info
              div(class: "bg-blue-50 rounded-lg p-4 border border-blue-200") do
                h3(class: "font-semibold text-blue-800 mb-2") { "How it works:" }
                ul(class: "text-sm text-blue-700 space-y-1") do
                  li { "• Hold device horizontally (landscape)" }
                  li { "• Point camera at barcode" }
                  li { "• Automatic detection and submission" }
                  li { "• View scanned items in My Scans" }
                end
              end
            end

            # Library Selection
            div(
              class: "bg-gray-50 rounded-lg p-4 mb-6",
              data_horizontal_barcode_scanner_target: "libraryStatus"
            ) do
              h3(class: "font-semibold text-gray-800 mb-3") { "Library Settings" }
              
              if Current.library
                p(class: "text-sm text-blue-800 mb-3") do
                  "Scanned items will be added to: "
                  span(class: "font-semibold") { Current.library.name }
                end
              else
                p(class: "text-sm text-gray-600 mb-3") { "Items will be scanned but not added to any library" }
              end

              # Library dropdown
              div do
                label(class: "text-xs text-gray-600 block mb-2") { "Change library:" }
                select(
                  data_horizontal_barcode_scanner_target: "librarySelect",
                  class: "w-full bg-white border border-gray-300 rounded-md px-3 py-2 text-sm"
                ) do
                  option(value: "", selected: !Current.library) { "None (just scan)" }
                  @libraries.each do |library|
                    option(value: library.name, selected: Current.library&.name == library.name) { library.name }
                  end
                end
              end
            end

            # Recent Scans Preview
            if @recent_scans.any?
              div(class: "flex-1") do
                h3(class: "font-semibold text-gray-800 mb-3") { "Recent Scans" }
                div(class: "space-y-2 max-h-64 overflow-y-auto") do
                  @recent_scans.each do |scan|
                    div(class: "bg-white border rounded-lg p-3 shadow-sm") do
                      if scan.product
                        div(class: "flex items-center gap-2") do
                          div(class: "text-xs text-gray-500") { scan.created_at.strftime("%H:%M") }
                          div(class: "flex-1 text-sm font-medium text-gray-800 truncate") do
                            scan.product.title || scan.product.ean
                          end
                        end
                      else
                        div(class: "text-sm text-gray-500") do
                          "EAN: #{scan.ean}"
                        end
                      end
                    end
                  end
                end
                
                div(class: "mt-4 pt-4 border-t") do
                  a(
                    href: "/scans",
                    class: "text-sm text-blue-600 hover:text-blue-800 underline"
                  ) { "View all scans →" }
                end
              end
            end
          end
        end
      end
    end
  end
end