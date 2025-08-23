class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def index
    @users = User.all
    render Components::Users::IndexView.new(users: @users)
  end

  def show
    @user = User.find(params[:id])
    render Components::Users::ShowView.new(user: @user)
  end

  def new
    @user = User.new
    render Components::Auth::SignupView.new(user: @user)
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session = @user.sessions.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      Current.session = session
      redirect_to root_path, notice: "Welcome! Your account has been created."
    else
      render Components::Auth::SignupView.new(user: @user), status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
