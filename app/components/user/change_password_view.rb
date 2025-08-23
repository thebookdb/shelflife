class Components::User::ChangePasswordView < Components::Base
  # include Rails.application.routes.url_helpers

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
              div(class: "flex items-center justify-between") do
                div(class: "flex items-center") do
                  div(class: "w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center") do
                    span(class: "text-2xl font-bold text-primary-700") do
                      "🔒"
                    end
                  end
                  div(class: "ml-4") do
                    h1(class: "text-2xl font-bold text-gray-900") { "Change Password" }
                    p(class: "text-gray-600") { "Update your account password" }
                  end
                end
                a(href: profile_path, class: "text-gray-600 hover:text-gray-900") do
                  "← Back to Profile"
                end
              end
            end

            # Form
            div(class: "px-6 py-6") do
              form_with(url: "/profile/update_password", method: :patch, local: true, class: "space-y-6") do |f|
                # Current password field
                div do
                  f.label :current_password, "Current Password", class: "block text-sm font-medium text-gray-700"
                  f.password_field :current_password,
                    required: true,
                    class: "mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                  if @user.errors[:current_password].any?
                    p(class: "mt-2 text-sm text-red-600") { @user.errors[:current_password].first }
                  end
                end

                # New password field
                div do
                  f.label "user[password]", "New Password", class: "block text-sm font-medium text-gray-700"
                  f.password_field "user[password]",
                    required: true,
                    class: "mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                  if @user.errors[:password].any?
                    p(class: "mt-2 text-sm text-red-600") { @user.errors[:password].first }
                  end
                end

                # Confirm password field
                div do
                  f.label "user[password_confirmation]", "Confirm New Password", class: "block text-sm font-medium text-gray-700"
                  f.password_field "user[password_confirmation]",
                    required: true,
                    class: "mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                  if @user.errors[:password_confirmation].any?
                    p(class: "mt-2 text-sm text-red-600") { @user.errors[:password_confirmation].first }
                  end
                end

                # Actions
                div(class: "mt-8 flex justify-end space-x-4") do
                  a(
                    href: profile_path,
                    class: "px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                  ) do
                    "Cancel"
                  end
                  f.submit "Update Password",
                    class: "px-4 py-2 text-sm font-medium text-white bg-primary-600 border border-transparent rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                end
              end
            end

            # Security note
            div(class: "px-6 py-4 bg-gray-50 border-t border-gray-200") do
              div(class: "flex items-start") do
                div(class: "flex-shrink-0") do
                  span(class: "text-yellow-400") { "⚠️" }
                end
                div(class: "ml-3") do
                  p(class: "text-sm text-gray-600") do
                    "After changing your password, you'll remain signed in on this device. "
                    "You may need to sign in again on other devices."
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
