# frozen_string_literal: true

class Components::Auth::SignupView < Components::Base
  # include Rails.application.routes.url_helpers
  include Phlex::Rails::Helpers::FormWith

  def initialize(user:)
    @user = user
  end

  def view_template
    div(class: "min-h-screen flex items-center mx-auto justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8") do
      div(class: "max-w-md w-full space-y-8") do
        div do
          h2(class: "mt-6 text-center text-3xl font-extrabold text-gray-900") do
            "Create your account"
          end
          p(class: "mt-2 text-center text-sm text-gray-600") do
            "Join ShelfLife to track your books"
          end
        end

        form_with(model: @user, url: signup_path, local: true, class: "mt-8 space-y-6") do |f|
          div(class: "space-y-4") do
            div do
              label(for: "user_email_address", class: "block text-sm font-medium text-gray-700") do
                "Email address"
              end
              f.email_field(:email_address,
                required: true,
                class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm",
                placeholder: "Email address"
              )
              render_field_errors(:email_address)
            end

            div do
              label(for: "user_password", class: "block text-sm font-medium text-gray-700") do
                "Password"
              end
              f.password_field(:password,
                required: true,
                class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm",
                placeholder: "Password"
              )
              render_field_errors(:password)
            end

            div do
              label(for: "user_password_confirmation", class: "block text-sm font-medium text-gray-700") do
                "Confirm Password"
              end
              f.password_field(:password_confirmation,
                required: true,
                class: "mt-1 appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm",
                placeholder: "Confirm password"
              )
              render_field_errors(:password_confirmation)
            end
          end

          div do
            f.submit("Sign up",
              class: "group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors"
            )
          end

          div(class: "text-center") do
            span(class: "text-sm text-gray-600") do
              "Already have an account? "
              a(href: signin_path, class: "font-medium text-primary-600 hover:text-primary-500") do
                "Sign in"
              end
            end
          end
        end
      end
    end
  end

  private

  def render_field_errors(field)
    return unless @user.errors[field].any?

    div(class: "mt-1") do
      @user.errors[field].each do |error|
        p(class: "text-sm text-red-600") { error }
      end
    end
  end
end
