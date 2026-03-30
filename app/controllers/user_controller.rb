class UserController < ApplicationController
  def show
    @user = Current.user
    @connection = TbdbConnection.instance
    quota_status = Tbdb.quota_status

    # Fetch fresh quota from /me if cache is empty and system has OAuth connection
    if quota_status.nil? && @connection.connected?
      begin
        client = Tbdb::Client.new
        client.get_me  # This will populate the cache via response headers
        quota_status = Tbdb.quota_status
      rescue => e
        Rails.logger.error "Failed to fetch quota from /me: #{e.message}"
      end
    end

    render Components::User::ProfileView.new(user: @user, connection: @connection, quota_status: quota_status)
  end

  def edit
    @user = Current.user
    render Components::User::ProfileEditView.new(user: @user)
  end

  def update
    @user = Current.user

    if @user.update(user_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      render Components::User::ProfileEditView.new(user: @user), status: :unprocessable_entity
    end
  end

  def change_password
    @user = Current.user
    render Components::User::ChangePasswordView.new(user: @user)
  end

  def update_password
    @user = Current.user

    unless @user.authenticate(params[:current_password])
      @user.errors.add(:current_password, "is incorrect")
      render Components::User::ChangePasswordView.new(user: @user), status: :unprocessable_entity
      return
    end

    if @user.update(password_params)
      redirect_to profile_path, notice: "Password updated successfully."
    else
      render Components::User::ChangePasswordView.new(user: @user), status: :unprocessable_entity
    end
  end

  def dismiss_onboarding
    Current.user.update_setting("onboarding_dismissed", true)
    redirect_to root_path
  end

  def update_dashboard_setting
    user = Current.user
    key = params[:key]
    value = params[:value]

    if key == "reorder_library"
      library_id = value["library_id"].to_s
      direction = value["direction"]
      order = user.get_setting("dashboard_library_order", []).map(&:to_s)

      # Initialize order with all library IDs if empty
      if order.empty?
        order = Library.where(user: [user, nil]).order(:name).pluck(:id).map(&:to_s)
      end

      idx = order.index(library_id)
      if idx
        swap_idx = (direction == "up") ? idx - 1 : idx + 1
        if swap_idx.between?(0, order.length - 1)
          order[idx], order[swap_idx] = order[swap_idx], order[idx]
        end
      end
      user.update_setting("dashboard_library_order", order)
    else
      user.update_setting(key, value)
    end

    head :ok
  end

  def update_setting
    @user = Current.user
    setting_enabled = params[:user][:hide_invalid_barcodes] == "true"

    success = @user.update_setting("hide_invalid_barcodes", setting_enabled)

    if success
      render json: {
        success: true,
        message: "Setting updated successfully",
        setting_value: @user.hide_invalid_barcodes?
      }
    else
      render json: {
        success: false,
        message: "Failed to update setting"
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email_address)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
