class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Wheelhouse: choose a new password", to: user.email_address
  end
end
