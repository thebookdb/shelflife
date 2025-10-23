class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend

  # Enable Pagy array extra for paginating arrays
  require 'pagy/extras/array'

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :redirect_to_signup_if_no_users
  before_action :set_current_library

  private

  def redirect_to_signup_if_no_users
    return if controller_name == "users" && action_name == "new"
    return if controller_name == "users" && action_name == "create"

    if User.count == 0
      redirect_to signup_path
    end
  end

  def set_current_library
    if session[:current_library_gid].present?
      Current.library = GlobalID::Locator.locate(session[:current_library_gid])
    end
  rescue ActiveRecord::RecordNotFound
    # Library was deleted, clear the session
    session[:current_library_gid] = nil
    Current.library = nil
  end
end
