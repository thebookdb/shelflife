class Components::Users::IndexView < Components::Base
  def initialize(users:)
    @users = users
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      render Components::Shared::NavigationView.new

      div(class: "pt-20 px-4") do
        div(class: "max-w-4xl mx-auto") do
          div(class: "mb-8") do
            h1(class: "text-3xl font-bold text-gray-900") { "Users" }
            p(class: "text-gray-600 mt-2") { "All registered users" }
          end

          if @users.any?
            div(class: "bg-white rounded-lg shadow-md overflow-hidden") do
              table(class: "min-w-full divide-y divide-gray-200") do
                thead(class: "bg-gray-50") do
                  tr do
                    th(class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") { "User" }
                    th(class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") { "Joined" }
                    th(class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") { "Library Items" }
                    th(class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") { "Total Scans" }
                    th(class: "relative px-6 py-3") { span(class: "sr-only") { "Actions" } }
                  end
                end

                tbody(class: "bg-white divide-y divide-gray-200") do
                  @users.each do |user|
                    render_user_row(user)
                  end
                end
              end
            end
          else
            div(class: "bg-white rounded-lg shadow-md p-8 text-center") do
              div(class: "text-6xl mb-4") { "👥" }
              h2(class: "text-xl font-semibold text-gray-800 mb-2") { "No users yet" }
              p(class: "text-gray-600") { "Users will appear here when they register" }
            end
          end
        end
      end
    end
  end

  private

  def render_user_row(user)
    tr do
      td(class: "px-6 py-4 whitespace-nowrap") do
        div(class: "flex items-center") do
          div(class: "w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center") do
            span(class: "text-sm font-bold text-primary-700") do
              user.email_address.first.upcase
            end
          end
          div(class: "ml-4") do
            div(class: "text-sm font-medium text-gray-900") { user.email_address }
          end
        end
      end

      td(class: "px-6 py-4 whitespace-nowrap text-sm text-gray-500") do
        user.created_at.strftime("%b %d, %Y")
      end

      td(class: "px-6 py-4 whitespace-nowrap text-sm text-gray-900") do
        user.library_items.count
      end

      td(class: "px-6 py-4 whitespace-nowrap text-sm text-gray-900") do
        user.scans.count
      end

      td(class: "px-6 py-4 whitespace-nowrap text-right text-sm font-medium") do
        a(href: user_path(user), class: "text-primary-600 hover:text-primary-900") { "View" }
      end
    end
  end
end
