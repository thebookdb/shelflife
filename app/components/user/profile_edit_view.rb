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
