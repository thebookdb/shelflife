class UserController < ApplicationController
  def show
    @user = Current.user
    render Components::User::ProfileView.new(user: @user)
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
