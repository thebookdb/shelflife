class Components::User::ProfileEditView < Components::Base
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
                      (@user.name.present? ? @user.name.first : @user.email_address.first).upcase
                    end
                  end
                  div(class: "ml-4") do
                    h1(class: "text-2xl font-bold text-gray-900") { "Edit Profile" }
                    p(class: "text-gray-600") { "Update your profile information" }
                  end
                end
                a(href: profile_path, class: "text-gray-600 hover:text-gray-900") do
                  "← Back to Profile"
                end
              end
            end

            # Form
            div(class: "px-6 py-6") do
              form_with(model: @user, url: profile_path, method: :patch, local: true, class: "space-y-6") do |f|
                # Name field
                div do
                  f.label :name, class: "block text-sm font-medium text-gray-700"
                  f.text_field :name,
                    class: "mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                  if @user.errors[:name].any?
                    p(class: "mt-2 text-sm text-red-600") { @user.errors[:name].first }
                  end
                end

                # Email field
                div do
                  f.label :email_address, "Email Address", class: "block text-sm font-medium text-gray-700"
                  f.email_field :email_address,
                    class: "mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                  if @user.errors[:email_address].any?
                    p(class: "mt-2 text-sm text-red-600") { @user.errors[:email_address].first }
                  end
                end
              end
            end

            # API Configuration Section
            div(id: "api-settings", class: "px-6 py-6 border-t border-gray-200") do
              h3(class: "text-lg font-medium text-gray-900 mb-6") { "API Configuration" }
              
              form_with(url: "/profile/api_token", method: :patch, local: true, class: "space-y-6") do |api_form|
                div do
                  api_form.label :thebookdb_api_token, "Personal TheBookDB API Token", class: "block text-sm font-medium text-gray-700"
                  p(class: "text-xs text-gray-500 mt-1 mb-2") do
                    plain "Enter your personal API token for TheBookDB.info service. "
                    if ENV["TBDB_API_TOKEN"].present?
                      plain "If left blank, the application will use the system default token."
                    else
                      plain "This is required as no system default is configured."
                    end
                  end
                  api_form.password_field :thebookdb_api_token,
                    value: @user.thebookdb_api_token,
                    placeholder: "Enter your personal API token...",
                    class: "mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                  
                  if @user.has_thebookdb_api_token?
                    p(class: "text-xs text-gray-400 mt-1") { "Leave blank to remove your personal token and use application default" }
                  end
                end

                div(class: "flex justify-end space-x-3") do
                  if @user.has_thebookdb_api_token?
                    a(
                      href: "/profile/api_token",
                      data: { method: :delete, confirm: "Are you sure you want to remove your personal API token?" },
                      class: "px-4 py-2 text-sm font-medium text-red-600 bg-white border border-red-300 rounded-md hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                    ) do
                      "Remove Token"
                    end
                  end
                  api_form.submit(@user.has_thebookdb_api_token? ? "Update Token" : "Set Token",
                    class: "px-4 py-2 text-sm font-medium text-white bg-primary-600 border border-transparent rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                  )
                end
              end
            end

            div(class: "px-6 py-6") do
              form_with(model: @user, url: profile_path, method: :patch, local: true, class: "space-y-6") do |f|
                div(class: "hidden") do
                  # Hidden fields to avoid affecting profile form
                end

                # Actions
                div(class: "mt-8 flex justify-end space-x-4") do
                  a(
                    href: profile_path,
                    class: "px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                  ) do
                    "Cancel"
                  end
                  f.submit "Save Changes",
                    class: "px-4 py-2 text-sm font-medium text-white bg-primary-600 border border-transparent rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                end
              end
            end
          end
        end
      end
    end
  end
end
