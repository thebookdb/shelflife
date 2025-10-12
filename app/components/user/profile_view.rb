class Components::User::ProfileView < Components::Base
  include Phlex::Rails::Helpers::TimeAgoInWords
  # include Rails.application.routes.url_helpers

  def initialize(user:, connection:, quota_status: nil)
    @user = user
    @connection = connection
    @quota_status = quota_status
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
              h3(class: "text-lg font-medium text-gray-900 mb-6") { "TBDB Integration" }

              div(class: "space-y-6") do
                # OAuth Connection Status
                div do
                  dt(class: "text-sm font-medium text-gray-700 mb-2") { "System Connection" }
                  dd(class: "text-xs text-gray-500 mb-3") { "Shared OAuth connection to TheBookDB.info for product data lookups." }

                  if @connection.status == 'invalid'
                    # Show invalid connection state with error message
                    div(class: "space-y-3") do
                      div(class: "flex items-start justify-between p-3 bg-red-50 border border-red-200 rounded") do
                        div(class: "flex-1") do
                          div(class: "text-sm font-medium text-red-800") { "Connection Invalid" }
                          if @connection.last_error.present?
                            div(class: "text-xs text-red-600 mt-1") { @connection.last_error }
                          end
                          if @connection.api_base_url.present?
                            div(class: "text-xs text-red-500 mt-1") { "OAuth tokens from: #{@connection.api_base_url}" }
                          end
                        end
                        a(
                          href: auth_tbdb_path,
                          class: "inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded text-white bg-red-600 hover:bg-red-700"
                        ) { "Reconnect" }
                      end
                    end
                  elsif @connection.connected?
                    div(class: "flex items-center justify-between p-3 bg-green-50 border border-green-200 rounded") do
                      div do
                        div(class: "text-sm font-medium text-green-800") { "Connected to TBDB" }
                        div(class: "text-xs text-green-600 mt-1") do
                          if @connection.api_base_url.present?
                            plain "#{@connection.api_base_url} • "
                          end
                          if @connection.token_expired?
                            plain "Auto-refreshing token as needed"
                          else
                            plain "Active • Expires #{@connection.expires_at.strftime('%b %d at %I:%M %p')}"
                          end
                        end
                        if @connection.verified_at.present?
                          div(class: "text-xs text-green-500 mt-1") do
                            plain "Last verified #{time_ago_in_words(@connection.verified_at)} ago"
                          end
                        end
                      end
                      a(
                        href: auth_tbdb_disconnect_path,
                        data: {
                          turbo_method: "delete",
                          turbo_confirm: "Are you sure you want to disconnect from TBDB? This will affect all users."
                        },
                        class: "text-sm text-red-600 hover:text-red-700 font-medium"
                      ) { "Disconnect" }
                    end
                  else
                    div(class: "flex items-center justify-between p-3 bg-gray-50 border border-gray-200 rounded") do
                      div do
                        div(class: "text-sm font-medium text-gray-700") { "Not Connected" }
                        div(class: "text-xs text-gray-500 mt-1") { "Connect for product data access" }
                      end
                      a(
                        href: auth_tbdb_path,
                        class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                      ) { "Connect to TBDB" }
                    end
                  end
                end

                # API Quota Status
                if @quota_status
                  div(class: "pt-6 border-t border-gray-200") do
                    dt(class: "text-sm font-medium text-gray-700 mb-2") { "Daily API Quota" }
                    dd(class: "text-xs text-gray-500 mb-3") { "Your current TBDB API usage for today" }

                    # Quota progress bar
                    div(class: "space-y-2") do
                      div(class: "flex items-center justify-between text-sm") do
                        span(class: "font-medium text-gray-900") do
                          plain "#{@quota_status[:remaining]} / #{@quota_status[:limit]} requests remaining"
                        end
                        span(class: quota_percentage_color) do
                          plain "#{@quota_status[:percentage]}%"
                        end
                      end

                      # Progress bar
                      div(class: "w-full bg-gray-200 rounded-full h-2") do
                        div(
                          class: "h-2 rounded-full #{quota_bar_color}",
                          style: "width: #{@quota_status[:percentage]}%"
                        )
                      end

                      # Reset time
                      if @quota_status[:reset_at]
                        div(class: "flex items-center justify-between text-xs text-gray-500") do
                          span { "Resets at #{@quota_status[:reset_at].strftime('%I:%M %p %Z')}" }
                          span { "Updated #{time_ago_in_words(@quota_status[:updated_at])} ago" }
                        end
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

  private

  def quota_percentage_color
    return "text-gray-600" unless @quota_status

    percentage = @quota_status[:percentage]
    if percentage >= 50
      "text-green-600 font-medium"
    elsif percentage >= 25
      "text-amber-600 font-medium"
    else
      "text-red-600 font-medium"
    end
  end

  def quota_bar_color
    return "bg-gray-400" unless @quota_status

    percentage = @quota_status[:percentage]
    if percentage >= 50
      "bg-green-500"
    elsif percentage >= 25
      "bg-amber-500"
    else
      "bg-red-500"
    end
  end
end
