class Api::V1::BaseController < ApplicationController
  before_action :authenticate

  protect_from_forgery with: :null_session

  private

  def render_json_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end

  def render_json_success(data, status = :ok)
    render json: data, status: status
  end
end
