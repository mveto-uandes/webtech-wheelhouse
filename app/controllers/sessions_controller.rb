class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  # Public: a visitor has no account for a policy to judge (docs/decisions.md).
  skip_after_action :verify_authorized, only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  # A wrong address and a wrong password get the same sentence, so the page
  # never tells whether an address has an account. The form comes back with the
  # address kept and the password empty, like any refused form.
  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      flash.now[:alert] = "That email address and password don't match an account."
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    authorize :session
    terminate_session
    redirect_to new_session_path, notice: "You signed out.", status: :see_other
  end
end
