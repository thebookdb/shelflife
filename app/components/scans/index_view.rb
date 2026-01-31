module Components
  module Scans
    class IndexView < Phlex::HTML
      include Phlex::Rails::Helpers::TurboStreamFrom

      def initialize(recent_scans:)
        @recent_scans = recent_scans
      end

      def view_template
        div(class: "min-h-screen bg-gray-50") do
          # Header Section
          div(class: "bg-white shadow-sm border-b border-gray-200") do
            div(class: "py-6") do
              div(class: "flex items-center justify-between mb-2") do
                h1(class: "text-2xl font-bold text-gray-800") { "My Scans" }
                div(class: "flex gap-3") do
                  a(
                    href: "/scanner",
                    class: "bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors text-sm font-medium flex items-center gap-2"
                  ) do
                    span { "📱" }
                    span { "Scan" }
                  end
                  a(
                    href: "/",
                    class: "text-blue-600 hover:text-blue-800 text-sm font-medium flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-blue-50 transition-colors"
                  ) do
                    span { "🏠" }
                    span { "Home" }
                  end
                end
              end
              p(class: "text-gray-600") { "Your scan history" }
            end
          end

          # Content Area
          div(class: "py-6") do
            div(class: "max-w-5xl mx-auto px-4 sm:px-6 lg:px-8") do
              # Add turbo stream subscription
              turbo_stream_from "scans"

              if @recent_scans.any?
                div(id: "recent_scans", class: "space-y-4") do
                  @recent_scans.each do |scan|
                    render Components::Scans::ScanItemView.new(scan: scan)
                  end
                end
              else
                div(id: "recent_scans") do
                  empty_state
                end
              end
            end
          end
        end
      end

      private

      def empty_state
        div(class: "bg-white rounded-lg shadow-md p-12 text-center") do
          div(class: "text-8xl mb-6") { "🔍" }
          h2(class: "text-3xl font-bold text-gray-800 mb-4") { "No scans yet" }
          p(class: "text-lg text-gray-600 mb-8 max-w-2xl mx-auto") { "Start scanning barcodes to build your scan history and track your library items" }

          a(
            href: "/scanner",
            class: "inline-flex items-center gap-3 bg-green-600 text-white px-8 py-4 rounded-lg hover:bg-green-700 transition-colors font-semibold text-lg shadow-lg hover:shadow-xl transform hover:scale-105"
          ) do
            span(class: "text-xl") { "📱" }
            span { "Start Scanning" }
          end
        end
      end
    end
  end
end
