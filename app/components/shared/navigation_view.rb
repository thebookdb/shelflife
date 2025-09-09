# frozen_string_literal: true

class Components::Shared::NavigationView < Components::Base
  #  include Rails.application.routes.url_helpers

  def view_template
    nav(class: "bg-white shadow-sm border-b border-primary-200 fixed top-0 left-0 right-0 z-50") do
      div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
        div(class: "flex justify-between items-center h-16") do
          # Logo/Brand
          div(class: "flex-shrink-0") do
            a(href: root_path, class: "text-2xl font-bold text-primary-700 hover:text-primary-600 transition-colors") do
              "ShelfLife"
            end
          end

          # Navigation Links
          div(class: "flex items-center space-x-4") do
            render_nav_links
            render_auth_links
            render_scan_button if authenticated?
          end
        end
      end
    end
  end

  private

  def render_nav_links
    if authenticated?
      div(class: "flex items-center space-x-2") do
        a(href: libraries_path, class: "text-primary-600 hover:text-primary-700 px-3 py-2 rounded-md text-sm font-medium transition-colors") do
          "Libraries"
        end
        a(href: scans_path, class: "text-primary-600 hover:text-primary-700 px-3 py-2 rounded-md text-sm font-medium transition-colors") do
          "Scans"
        end
      end
    end
  end

  def render_auth_links
    if authenticated?
      # User is signed in
      div(class: "flex items-center space-x-2") do
        a(href: profile_path, class: "text-sm text-gray-700 hover:text-gray-900") do
          "Hello, #{Current.user.name.present? ? Current.user.name : Current.user.email_address}"
        end
        a(
          href: signout_path,
          data: { turbo_method: :delete },
          class: "text-primary-600 hover:text-primary-700 px-3 py-2 rounded-md text-sm font-medium transition-colors"
        ) do
          "Sign out"
        end
      end
    else
      # User is not signed in
      div(class: "flex items-center space-x-2") do
        if ::User.count == 0
          # No users exist, show register link
          a(href: signup_path, class: "bg-primary-600 hover:bg-primary-700 text-white px-3 py-2 rounded-md text-sm font-medium transition-colors") do
            "Register"
          end
        else
          # Users exist, show sign in link
          a(href: signin_path, class: "text-primary-600 hover:text-primary-700 px-3 py-2 rounded-md text-sm font-medium transition-colors") do
            "Sign in"
          end
        end
      end
    end
  end

  def render_scan_button
    a(
      href: scanner_path,
      class: "bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors flex items-center gap-1",
      title: "Adaptive Scanner - Automatically optimizes for your device orientation"
    ) do
      span { "📱" }
      span { "Scan" }
    end
  end

  def authenticated?
    Current.user.present?
  end
end
