class Components::User::ProfileView < Components::Base
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
              div(class: "flex items-center") do
                div(class: "w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center") do
                  span(class: "text-2xl font-bold text-primary-700") do
                    (@user.name.present? ? @user.name.first : @user.email_address.first).upcase
                  end
                end
                div(class: "ml-4") do
                  h1(class: "text-2xl font-bold text-gray-900") { "Your Profile" }
                  p(class: "text-gray-600") { @user.name.present? ? @user.name : @user.email_address }
                end
              end
            end

            # Profile Details
            div(class: "px-6 py-6") do
              dl(class: "grid grid-cols-1 gap-6") do
                div do
                  dt(class: "text-sm font-medium text-gray-500") { "Name" }
                  dd(class: "mt-1 text-sm text-gray-900") { @user.name.present? ? @user.name : "Not set" }
                end

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

            # Settings Section
            div(class: "px-6 py-6 border-t border-gray-200") do
              h3(class: "text-lg font-medium text-gray-900 mb-6") { "Settings" }
              
              form_with(
                model: @user,
                url: "/profile/settings",
                method: :patch,
                local: false,
                data: { controller: "settings-form" },
                class: "space-y-4"
              ) do |form|
                # Hide invalid barcodes setting
                div(class: "flex items-center justify-between") do
                  div do
                    dt(class: "text-sm font-medium text-gray-700") { "Hide Invalid ISBNs/GTIN barcodes" }
                    dd(class: "text-xs text-gray-500 mt-1") { "Hide products with invalid GTIN check digits or non-ISBN barcodes from listings" }
                  end
                  div(class: "ml-4") do
                    label(class: "relative inline-flex items-center cursor-pointer") do
                      form.check_box(
                        :hide_invalid_barcodes,
                        {
                          checked: @user.hide_invalid_barcodes?,
                          data: { action: "change->settings-form#updateSetting" },
                          class: "sr-only peer"
                        },
                        "true",
                        "false"
                      )
                      div(class: "w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600")
                    end
                  end
                end
                
                # Status message area
                div(
                  id: "settings-status",
                  data: { settings_form_target: "status" },
                  class: "hidden text-sm mt-2"
                )
              end
            end

            # API Configuration Section
            div(class: "px-6 py-6 border-t border-gray-200") do
              h3(class: "text-lg font-medium text-gray-900 mb-6") { "API Configuration" }
              
              div(class: "space-y-4") do
                div do
                  dt(class: "text-sm font-medium text-gray-700 mb-2") { "TheBookDB API Token" }
                  dd(class: "text-xs text-gray-500 mb-3") { "Personal API token for accessing TheBookDB.info service. Falls back to application default if not set." }
                  
                  if @user.has_thebookdb_api_token?
                    div(class: "text-sm text-gray-900 font-mono bg-gray-50 px-3 py-2 rounded border") do
                      token = @user.thebookdb_api_token
                      masked_token = token[0..7] + "..." + token[-4..-1]
                      masked_token
                    end
                    div(class: "text-xs text-green-600 mt-1") { "Using personal token" }
                  else
                    if ENV["TBDB_API_TOKEN"].present?
                      div(class: "text-sm text-gray-600 bg-gray-50 px-3 py-2 rounded border") do
                        "Using application default"
                      end
                    else
                      div(class: "text-sm text-red-600 bg-red-50 px-3 py-2 rounded border border-red-200") do
                        "No token configured"
                      end
                    end
                  end
                end
              end
            end

            # Actions
            div(class: "px-6 py-4 bg-gray-50 border-t border-gray-200") do
              div(class: "flex justify-end space-x-4") do
                a(href: edit_profile_path, class: "text-primary-600 hover:text-primary-700 font-medium") do
                  "Edit Profile"
                end
                a(href: change_password_path, class: "text-gray-600 hover:text-gray-900 font-medium") do
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
