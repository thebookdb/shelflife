module Components
  module Scans
    class IndexView < Phlex::HTML
      include Phlex::Rails::Helpers::TurboStreamFrom

      def initialize(recent_scans:)
        @recent_scans = recent_scans
      end

      def view_template
        div(class: "max-w-4xl mx-auto p-4") do
          # Add turbo stream subscription
          turbo_stream_from "scans"

          h1(class: "text-2xl font-bold text-gray-900 mb-6") { "Recently Scanned" }

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

      private


      def empty_state
        div(class: "text-center py-12") do
          div(class: "text-6xl mb-4") { "🔍" }
          h2(class: "text-xl font-semibold text-gray-800 mb-2") { "No scans yet" }
          p(class: "text-gray-600 mb-4") { "Start scanning barcodes to see your history here" }
          a(
            href: "/scanner",
            class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
          ) do
            "Start Scanning"
          end
        end
      end
    end
  end
end
