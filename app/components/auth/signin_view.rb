# frozen_string_literal: true

class Components::Auth::SigninView < Components::Base
  # include Rails.application.routes.url_helpers
  include Phlex::Rails::Helpers::FormWith

  def view_template
    div(class: "min-h-screen flex mx-auto items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8") do
      div(class: "max-w-md w-full space-y-8") do
        div do
          h2(class: "mt-6 text-center text-3xl font-extrabold text-gray-900") do
            "Sign in to your account"
          end
          p(class: "mt-2 text-center text-sm text-gray-600") do
            "Welcome back to ShelfLife"
          end
        end

        form_with(url: signin_path, local: true, class: "mt-8 space-y-6") do |f|
          div(class: "space-y-4") do
            div do
              label(for: "email_address", class: "block text-sm font-medium text-gray-700") do
                "Email address"
              end
              f.email_field(:email_address,
                required: true,
                class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm",
                placeholder: "Email address"
              )
            end

            div do
              label(for: "password", class: "block text-sm font-medium text-gray-700") do
                "Password"
              end
              f.password_field(:password,
                required: true,
                class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm",
                placeholder: "Password"
              )
            end
          end

          div do
            f.submit("Sign in",
              class: "group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors"
            )
          end

          div(class: "text-center") do
            span(class: "text-sm text-gray-600") do
              "Don't have an account? "
              a(href: signup_path, class: "font-medium text-primary-600 hover:text-primary-500") do
                "Sign up"
              end
            end
          end
        end
      end
    end
  end
end
