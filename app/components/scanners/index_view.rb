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
        #barcode-scanner video {
          width: 100% !important;
          height: 100% !important;
          object-fit: cover !important;
          position: absolute !important;
          top: 0 !important;
          left: 0 !important;
        }
        #barcode-scanner {
          background: transparent !important;
          border: none !important;
          padding: 0 !important;
          width: 100% !important;
          height: 100% !important;
          overflow: hidden !important;
        }
      CSS
    end

    # Portrait: flex-col (camera top, controls bottom)
    # Landscape: flex-row (camera 2/3 left, controls 1/3 right)
    div(
      class: "fixed inset-0 top-28 bg-gray-900 flex flex-col landscape:flex-row",
      data_controller: "barcode-scanner"
    ) do
      # Camera area — flex-1 in portrait, 2/3 width in landscape
      div(class: "flex-1 landscape:flex-none landscape:w-2/3 landscape:h-full relative overflow-hidden") do
        # Scanner element (hidden until scanning)
        div(
          id: "barcode-scanner",
          data_barcode_scanner_target: "scanner",
          class: "hidden absolute inset-0"
        )

        # Placeholder — shown before scanning starts
        div(
          data_barcode_scanner_target: "placeholder",
          class: "absolute inset-0 flex flex-col items-center justify-center"
        ) do
          div(class: "relative w-64 h-44 mb-6") do
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

        # Scanning overlay (hidden until scanning)
        div(class: "absolute inset-0 z-20 pointer-events-none hidden",
          data_barcode_scanner_target: "scanOverlay") do

          # Active camera label — top center
          div(
            data_barcode_scanner_target: "cameraLabel",
            class: "absolute top-2 left-1/2 -translate-x-1/2 bg-black/40 backdrop-blur-sm rounded px-2 py-0.5"
          ) do
            span(class: "text-white text-[11px] leading-tight whitespace-nowrap")
          end

          # Stop button — bottom center
          div(class: "absolute bottom-6 left-0 right-0 flex justify-center pointer-events-auto") do
            button(
              type: "button",
              data_action: "click->barcode-scanner#stopScanning",
              data_barcode_scanner_target: "stopButton",
              class: "bg-red-600 text-white px-8 py-3 rounded-xl font-semibold shadow-lg text-base"
            ) { "Stop" }
          end

          # Camera drawer tab — left edge, vertically centered
          div(
            data_barcode_scanner_target: "cameraTab",
            data_action: "click->barcode-scanner#toggleCameraDrawer",
            class: "absolute left-0 top-1/2 -translate-y-1/2 bg-white/80 backdrop-blur rounded-r-lg px-1.5 py-3 shadow-lg cursor-pointer pointer-events-auto transition-opacity",
          ) do
            span(class: "text-gray-700 text-sm") { "›" }
          end

          # Camera drawer panel — slides from left
          div(
            data_barcode_scanner_target: "cameraDrawer",
            class: "absolute left-0 top-1/2 -translate-y-1/2 -translate-x-full bg-white/90 backdrop-blur rounded-r-xl shadow-xl p-3 pointer-events-auto transition-transform duration-200 ease-out w-56"
          ) do
            div(class: "flex items-center justify-between mb-2") do
              span(class: "text-xs font-semibold text-gray-600 uppercase tracking-wide") { "Camera" }
              button(
                type: "button",
                data_action: "click->barcode-scanner#toggleCameraDrawer",
                class: "text-gray-400 hover:text-gray-600 text-sm leading-none"
              ) { "✕" }
            end
            div(data_barcode_scanner_target: "cameraList", class: "space-y-1")
          end
        end
      end

      # Control panel — bottom in portrait, right 1/3 in landscape
      div(class: "bg-white px-4 pt-3 pb-4 flex flex-col gap-2 shadow-[0_-4px_16px_rgba(0,0,0,0.15)] landscape:flex-1 landscape:border-l landscape:border-gray-200 landscape:shadow-none landscape:overflow-y-auto") do
        button(
          type: "button",
          data_action: "click->barcode-scanner#startScanning",
          data_barcode_scanner_target: "startButton",
          class: "w-full bg-green-600 text-white py-4 rounded-xl font-semibold text-lg shadow flex items-center justify-center gap-2 active:bg-green-700"
        ) do
          span { "📷" }
          span { "Start Scanning" }
        end

        div do
          p(class: "text-xs font-medium text-gray-400 uppercase tracking-wide mb-1.5") { "Recent" }
          div(id: "scanner-recent-items", class: "space-y-1 max-h-32 overflow-y-auto p-0.5") do
            if @recent_items.any?
              @recent_items.first(5).each do |item|
                render_recent_item(item)
              end
            end
          end
        end

        div(data_barcode_scanner_target: "libraryStatus", class: "mt-auto pt-2 border-t border-gray-100") do
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
      end
    end
  end

  private

  def render_recent_item(item, highlight: false)
    classes = "flex items-center gap-2 py-1.5 px-2 rounded-lg transition-all duration-700"
    classes += " bg-green-100 ring-2 ring-green-400 scanner-highlight" if highlight

    div(class: classes) do
      span(class: "text-xs text-gray-400 flex-shrink-0") { item.date_added.strftime("%H:%M") }
      span(class: "text-sm text-gray-700 truncate flex-1") do
        item.product&.title || item.product&.gtin || "Unknown"
      end
    end
  end
end
