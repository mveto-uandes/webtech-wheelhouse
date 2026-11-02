# Sign-up: anyone can make an account, with the default role and no member of
# the staff. Only the seed or the console change those.
class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  # Public: whoever signs up has no account yet (docs/decisions.md).
  skip_after_action :verify_authorized, only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      start_new_session_for @user
      WelcomeMailer.welcome(@user).deliver_later
      redirect_to after_authentication_url, notice: "Welcome to Wheelhouse. Your account #{@user.email_address} is ready."
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    # No role and no employee: an account can't promote itself.
    def registration_params
      params.expect(user: [ :email_address, :password, :password_confirmation ])
    end
end
