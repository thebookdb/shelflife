class Components::Scanners::IndexView < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(recent_scans:, libraries:)
    @recent_scans = recent_scans
    @libraries = libraries
  end

  def view_template
    # CSS for html5-qrcode styling
    style do
      raw(<<~CSS.html_safe)
        #portrait-scanner, #landscape-scanner {
          background-color: #1f2937 !important;
          padding: 10px !important;
        }
        #portrait-scanner div, #landscape-scanner div {
          color: white !important;
          margin-bottom: 8px !important;
        }
        #portrait-scanner button, #landscape-scanner button {
          background-color: #374151 !important;
          color: white !important;
          border: 1px solid #6b7280 !important;
          margin: 4px !important;
          padding: 8px 12px !important;
          border-radius: 6px !important;
        }
        #portrait-scanner a, #landscape-scanner a {
          color: #60a5fa !important;
          display: block !important;
          margin: 8px 0 !important;
        }
        #portrait-scanner select, #landscape-scanner select {
          background-color: #374151 !important;
          color: white !important;
          border: 1px solid #6b7280 !important;
          margin: 4px !important;
          padding: 6px !important;
          border-radius: 4px !important;
          min-width: 150px !important;
        }
        #portrait-scanner input, #landscape-scanner input {
          background-color: #374151 !important;
          color: white !important;
          border: 1px solid #6b7280 !important;
          margin: 4px !important;
          padding: 6px !important;
          border-radius: 4px !important;
        }
        /* Specific html5-qrcode element styling */
        #portrait-scanner .qr-shaded-region, #landscape-scanner .qr-shaded-region {
          background-color: rgba(0, 0, 0, 0.5) !important;
        }
        #portrait-scanner .qr-scanner-ui, #landscape-scanner .qr-scanner-ui {
          margin: 10px 0 !important;
        }
        #portrait-scanner .qr-scanner-ui > div, #landscape-scanner .qr-scanner-ui > div {
          margin: 6px 0 !important;
        }
        /* Style the camera selection and torch controls */
        #portrait-scanner div[style*="display: flex"], #landscape-scanner div[style*="display: flex"] {
          flex-wrap: wrap !important;
          gap: 8px !important;
          justify-content: center !important;
          align-items: center !important;
        }
        /* Ensure html5-qrcode UI doesn't overflow the scanner area */
        #portrait-scanner > div, #landscape-scanner > div {
          max-height: 100% !important;
          overflow-y: auto !important;
        }
        /* Position camera controls at the bottom of scanner area */
        #portrait-scanner .qr-scanner-ui {
          position: absolute !important;
          bottom: 10px !important;
          left: 10px !important;
          right: 10px !important;
          background-color: rgba(31, 41, 55, 0.9) !important;
          padding: 10px !important;
          border-radius: 8px !important;
        }

        /* In landscape mode, position ALL camera control elements in the right panel */
        #landscape-scanner .qr-scanner-ui,
        #landscape-scanner div[id*="dashboard"],
        #landscape-scanner div[class*="dashboard"],
        #landscape-scanner div[id$="__dashboard_section_csr"],
        #landscape-scanner div[id$="__scan_region_highlight_css"],
        #landscape-scanner div[id*="__scan_region__dashboard"] {
          position: fixed !important;
          top: 80px !important;
          right: 20px !important;
          left: auto !important;
          width: 280px !important;
          max-width: 280px !important;
          background-color: rgba(31, 41, 55, 0.95) !important;
          padding: 12px !important;
          border-radius: 8px !important;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3) !important;
          z-index: 30 !important;
          border: 1px solid rgba(75, 85, 99, 0.8) !important;
        }
        /* Fix the dashboard section positioning */
        #portrait-scanner__dashboard_section_csr, #landscape-scanner__dashboard_section_csr {
          position: relative !important;
          z-index: 10 !important;
          background-color: rgba(31, 41, 55, 0.95) !important;
          padding: 12px !important;
          margin-bottom: 15px !important;
          border-radius: 8px !important;
        }
        /* Ensure content flows properly after dashboard */
        #portrait-scanner__dashboard_section_csr + *, #landscape-scanner__dashboard_section_csr + * {
          margin-top: 15px !important;
        }
      CSS
    end

    # Adaptive scanner layout - break out of main container
    div(
      class: "fixed inset-0 top-16 bg-gray-50 overflow-hidden",
      data_controller: "barcode-scanner",
      data_barcode_scanner_scanner_page_value: "true"
    ) do
      # Portrait Layout (mobile/vertical)
      div(
        class: "h-full flex-col portrait:flex landscape:hidden",
        data_barcode_scanner_target: "portraitLayout"
      ) do
        render_portrait_layout
      end

      # Landscape Layout (horizontal/desktop)
      div(
        class: "h-full landscape:flex portrait:hidden",
        data_barcode_scanner_target: "landscapeLayout"
      ) do
        render_landscape_layout
      end
    end
  end

  private

  def render_portrait_layout
    # Floating controls at top
    div(class: "absolute top-4 left-4 right-4 z-20 flex justify-between items-center") do
      # Stop button on the left
      button(
        type: "button",
        data_action: "click->barcode-scanner#stopScanning",
        data_barcode_scanner_target: "stopButton",
        class: "bg-red-600 text-white px-3 py-2 rounded-lg hover:bg-red-700 transition-colors font-medium shadow-lg hidden"
      ) do
        span { "⏹ Stop" }
      end

      # Orientation display in center
      div(
        data_barcode_scanner_target: "orientationDisplay",
        class: "bg-blue-600/90 text-white px-3 py-1 rounded-lg text-sm font-medium"
      ) { "📲 Portrait" }

      # Scan result display on the right
      div(
        data_barcode_scanner_target: "scanResult",
        class: "bg-gray-800/90 backdrop-blur-sm text-white px-3 py-2 rounded-lg hidden"
      ) do
        p(data_barcode_scanner_target: "result", class: "font-mono text-sm text-white")
      end
    end

    # Scanner Area - Takes up 70% of height
    div(
      class: "flex-none h-[70vh] bg-black relative",
      data_barcode_scanner_target: "portraitScannerArea"
    ) do
      # Portrait scanner element
      div(
        id: "portrait-scanner",
        data_barcode_scanner_target: "portraitScanner",
        class: "hidden w-full h-full relative z-0"
      )

      # Placeholder when not scanning
      div(
        data_barcode_scanner_target: "portraitPlaceholder",
        class: "absolute inset-0 flex items-center justify-center text-white z-10"
      ) do
        div(class: "text-center") do
          div(class: "text-6xl mb-4") { "📷" }
          p(class: "text-xl mb-2") { "Adaptive Scanner" }
          p(class: "text-lg opacity-75") { "Portrait Mode" }
          p(class: "text-sm opacity-50 mt-4") { "Camera will appear here when scanning starts" }
        end
      end
    end

    # Control Panel - Bottom 30% of screen with proper scrolling
    div(class: "flex-1 bg-white rounded-t-xl shadow-xl flex flex-col min-h-0") do
      div(class: "flex-1 overflow-y-auto") do
        render_controls
      end
    end
  end

  def render_landscape_layout
    # Scanner Area - Left 2/3 of screen
    div(
      class: "flex-none w-2/3 bg-black relative",
      data_barcode_scanner_target: "landscapeScannerArea"
    ) do
      # Landscape scanner element
      div(
        id: "landscape-scanner",
        data_barcode_scanner_target: "landscapeScanner",
        class: "hidden w-full h-full relative z-0"
      )

      # Floating controls at top
      div(class: "absolute top-4 left-4 right-4 z-20 flex justify-between items-center") do
        # Stop button on the left
        button(
          type: "button",
          data_action: "click->barcode-scanner#stopScanning",
          data_barcode_scanner_target: "stopButton",
          class: "bg-red-600 text-white px-3 py-2 rounded-lg hover:bg-red-700 transition-colors font-medium shadow-lg hidden"
        ) do
          span { "⏹ Stop" }
        end

        # Orientation display in center
        div(
          data_barcode_scanner_target: "orientationDisplay",
          class: "bg-blue-600/90 text-white px-3 py-1 rounded-lg text-sm font-medium"
        ) { "📱 Landscape" }

        # Scan result display on the right
        div(
          data_barcode_scanner_target: "scanResult",
          class: "bg-gray-800/90 backdrop-blur-sm text-white px-3 py-2 rounded-lg hidden"
        ) do
          p(data_barcode_scanner_target: "result", class: "font-mono text-sm text-white")
        end
      end

      # Placeholder when not scanning
      div(
        data_barcode_scanner_target: "landscapePlaceholder",
        class: "absolute inset-0 flex items-center justify-center text-white z-10"
      ) do
        div(class: "text-center") do
          div(class: "text-8xl mb-4") { "📷" }
          p(class: "text-xl mb-2") { "Adaptive Scanner" }
          p(class: "text-lg opacity-75") { "Landscape Mode" }
          p(class: "text-sm opacity-50 mt-4") { "Camera will appear here when scanning starts" }
        end
      end
    end

    # Control Panel - Right 1/3 of screen
    div(class: "flex-1 bg-white border-l border-gray-200 overflow-y-auto") do
      render_controls
    end
  end

  def render_controls
    div(class: "p-4 landscape:p-6") do
      # Header - more compact in portrait
      div(class: "mb-4 landscape:mb-6") do
        h2(class: "text-xl landscape:text-2xl font-bold text-gray-800 mb-1 landscape:mb-2") { "Adaptive Scanner" }
        p(class: "text-xs landscape:text-sm text-gray-600") { "Automatically optimizes for your device orientation" }
      end

      # Start button - more compact in portrait
      button(
        type: "button",
        data_action: "click->barcode-scanner#startScanning",
        data_barcode_scanner_target: "startButton",
        class: "w-full bg-green-600 text-white py-3 landscape:py-4 px-4 landscape:px-6 rounded-lg hover:bg-green-700 transition-colors font-medium shadow-lg flex items-center justify-center gap-2 landscape:gap-3 mb-3 landscape:mb-4"
      ) do
        span(class: "text-xl landscape:text-2xl") { "📱" }
        span(class: "text-base landscape:text-lg") { "Start Scanning" }
      end

      # Info section - more compact in portrait
      div(class: "bg-blue-50 rounded-lg p-3 landscape:p-4 border border-blue-200 mb-4 landscape:mb-6") do
        h3(class: "font-semibold text-blue-800 mb-1 landscape:mb-2 text-sm landscape:text-base") { "How it works:" }
        ul(class: "text-xs landscape:text-sm text-blue-700 space-y-0.5 landscape:space-y-1") do
          li { "• Automatically detects device orientation" }
          li { "• Switches between portrait/landscape modes" }
          li { "• Optimizes camera settings for each mode" }
          li { "• Continuous barcode detection and submission" }
        end
      end

      # Library Selection - more compact in portrait
      div(
        class: "bg-gray-50 rounded-lg p-3 landscape:p-4 mb-4 landscape:mb-6",
        data_barcode_scanner_target: "libraryStatus"
      ) do
        h3(class: "font-semibold text-gray-800 mb-2 landscape:mb-3 text-sm landscape:text-base") { "Library Settings" }

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
            data_barcode_scanner_target: "librarySelect",
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
