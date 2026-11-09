class ApplicationMailer < ActionMailer::Base
  # In production the sender is the address the SMTP provider has verified, kept in
  # the production credentials (smtp.from). Development writes files and keeps the
  # made-up sender of Lab 11.
  default from: -> { Rails.application.credentials.dig(:smtp, :from) || "Wheelhouse <no-reply@wheelhouse.localhost>" }
  layout "mailer"
end
