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
          end
        end
      end
    end
  end

  private

  def render_nav_links
    if authenticated?
      div(class: "flex items-center space-x-2") do
        a(href: root_path, class: "text-primary-600 hover:text-primary-700 px-3 py-2 rounded-md text-sm font-medium transition-colors") { "Dashboard" }
        a(href: products_path, class: "text-primary-600 hover:text-primary-700 px-3 py-2 rounded-md text-sm font-medium transition-colors") { "Items" }
        a(href: libraries_path, class: "text-primary-600 hover:text-primary-700 px-3 py-2 rounded-md text-sm font-medium transition-colors") { "Libraries" }
      end
    end
  end

  def render_auth_links
    if authenticated?
      # User is signed in
      div(class: "relative") do
        details(class: "group") do
          summary(class: "list-none cursor-pointer") do
            div(
              class: "w-8 h-8 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-semibold text-sm hover:bg-primary-200 transition-colors select-none",
              title: Current.user.name.presence || Current.user.email_address
            ) do
              plain user_initials
            end
          end

          div(class: "absolute right-0 mt-2 w-44 bg-white rounded-lg shadow-lg border border-gray-100 py-1 z-50") do
            a(href: profile_path, class: "block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors") { "User Profile" }
            a(
              href: signout_path,
              data: {turbo_method: :delete},
              class: "block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
            ) { "Sign Out" }
          end
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

  def authenticated?
    Current.user.present?
  end

  def user_initials
    name = Current.user.name.presence || Current.user.email_address
    name.split(/[\s@]/).first(2).map { |p| p[0].upcase }.join
  end
end
