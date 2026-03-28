class Components::Shared::OnboardingModalView < Components::Base
  def view_template
    div(class: "fixed inset-0 z-50 flex items-center justify-center") do
      div(class: "absolute inset-0 bg-black/50")

      div(class: "relative bg-white rounded-2xl shadow-2xl p-8 max-w-md w-full mx-4") do
        div(class: "text-center mb-6") do
          div(class: "text-6xl mb-4") { "📚" }
          h2(class: "text-2xl font-bold text-gray-900") { "Welcome to ShelfLife" }
          p(class: "text-gray-500 mt-2") { "Your personal library for books, games, films, and more." }
        end

        div(class: "bg-blue-50 rounded-xl p-5 mb-6") do
          h3(class: "font-semibold text-blue-800 mb-3") { "How it works" }
          ul(class: "space-y-2 text-blue-700 text-sm") do
            [
              "Tap Scan to open the camera",
              "Point the camera at a barcode",
              "Product info appears instantly",
              "Add it to your library"
            ].each do |step|
              li(class: "flex items-start gap-2") do
                span(class: "text-green-500 font-bold mt-0.5") { "✓" }
                span { step }
              end
            end
          end
        end

        form_with(url: dismiss_onboarding_path, method: :post, local: true) do |f|
          f.button(
            type: "submit",
            class: "w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-3 rounded-lg transition-colors"
          ) { "Got it, let's go!" }
        end
      end
    end
  end
end
