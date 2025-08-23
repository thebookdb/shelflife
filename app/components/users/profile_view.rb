class Components::Users::ProfileView < Components::Base
  include Rails.application.routes.url_helpers

  def initialize(user:)
    @user = user
  end

  def view_template
    div(class: "min-h-screen bg-gray-50") do
      render Components::Shared::NavigationView.new

      div(class: "pt-20 px-4") do
        div(class: "max-w-2xl mx-auto") do
          div(class: "bg-white rounded-lg shadow-md") do
            # Header
            div(class: "px-6 py-8 border-b border-gray-200") do
              div(class: "flex items-center") do
                div(class: "w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center") do
                  span(class: "text-2xl font-bold text-primary-700") do
                    @user.email_address.first.upcase
                  end
                end
                div(class: "ml-4") do
                  h1(class: "text-2xl font-bold text-gray-900") { "Your Profile" }
                  p(class: "text-gray-600") { @user.email_address }
                end
              end
            end

            # Profile Details
            div(class: "px-6 py-6") do
              dl(class: "grid grid-cols-1 gap-6") do
                div do
                  dt(class: "text-sm font-medium text-gray-500") { "Email Address" }
                  dd(class: "mt-1 text-sm text-gray-900") { @user.email_address }
                end

                div do
                  dt(class: "text-sm font-medium text-gray-500") { "Member Since" }
                  dd(class: "mt-1 text-sm text-gray-900") { @user.created_at.strftime("%B %d, %Y") }
                end

                div do
                  dt(class: "text-sm font-medium text-gray-500") { "Recent Scans" }
                  dd(class: "mt-1 text-sm text-gray-900") do
                    span { @user.scans.count.to_s }
                    span(class: "text-gray-500 ml-1") { "total scans" }
                  end
                end
              end
            end

            # Actions
            div(class: "px-6 py-4 bg-gray-50 border-t border-gray-200") do
              div(class: "flex justify-end space-x-4") do
                a(href: new_password_path, class: "text-gray-600 hover:text-gray-900 font-medium") do
                  "Change Password"
                end
                a(href: signout_path, method: :delete, class: "text-red-600 hover:text-red-700 font-medium") do
                  "Sign Out"
                end
              end
            end
          end
        end
      end
    end
  end
end
