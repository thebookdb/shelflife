class Components::Shared::ActionBarView < Components::Base
  def view_template
    return unless Current.user

    div(id: "action-bar", class: "bg-orange-500 fixed top-16 left-0 right-0 z-40") do
      div(class: "flex items-center justify-center gap-4 h-12") do
        a(
          href: new_product_path,
          class: "flex items-center gap-2 bg-orange-400 hover:bg-orange-300 text-white text-sm font-medium px-5 py-1.5 rounded-lg transition-colors"
        ) { "＋ Create new Item" }
        a(
          href: scanner_path,
          class: "flex items-center gap-2 bg-orange-400 hover:bg-orange-300 text-white text-sm font-medium px-5 py-1.5 rounded-lg transition-colors"
        ) { "📱 Scan new Item" }
      end
    end
  end
end
