class PasswordResetsController < ApplicationController
  before_filter :find_password_reset_token, only: [:show, :update]
  before_filter :check_for_expired_token, only: [:show, :update]

  def new
  end

  def create
    if params[:email] && @user = User.where(email: params[:email]).first
      @password_reset_token = @user.password_reset_tokens.create
      Mailer.password_reset(
        @user.email,
        password_reset_with_token_url(
          @password_reset_token, @password_reset_token.token
        )
      ).deliver
      flash[:notice] = "An email with further instructions has been sent"
      redirect_to login_users_url
    else
      flash.now[:notice] = "Couldn't find a user with that email address"
      render action: :new
    end
  end

  def show
    @user = @password_reset_token.user
  end

  def update
    @user = @password_reset_token.user
    if !user_params[:password].blank? && @user.update_attributes(user_params)
      @password_reset_token.destroy
      @current_user = @user
      store_session_authentication
      flash[:notice] = "Your password has been changed"
      redirect_to root_url
    else
      render action: :show
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :confirm_password)
  end

  def find_password_reset_token
    begin
      @password_reset_token = PasswordResetToken.find(params[:id])
    rescue ActiveRecord::RecordNotFound
    end
    unless @password_reset_token && @password_reset_token.token == params[:token]
      flash[:notice] = "Invalid password reset request"
      redirect_to login_users_url and return
    end
  end

  def check_for_expired_token
    if @password_reset_token.expired?
      @password_reset_token.destroy
      flash[:notice] = "Your password reset link has expired"
      redirect_to login_users_url and return
    end
  end

end
