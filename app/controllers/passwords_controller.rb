class PasswordsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create edit update ]
  # Public: the person has forgotten how to sign in (docs/decisions.md).
  skip_after_action :verify_authorized, only: %i[ new create edit update ]
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }

  def new
  end

  # The same answer whether the address has an account or not.
  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "If that address has an account, an email with a link to choose a new password is on its way."
  end

  def edit
  end

  def update
    @user.assign_attributes(params.permit(:password, :password_confirmation))
    # has_secure_password ignores a blank password and would keep the old one.
    @user.errors.add(:password, :blank) if params[:password].blank?

    if @user.errors.none? && @user.save
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Your password was changed. Sign in with the new one."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "That link is no longer valid: it was already used, or it expired. Ask for a new one."
    end
end
