require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Wheelhouse has no domain name, so it has no certificate: it answers over plain
  # HTTP at the IP of the droplet (APP_HOST, set in config/deploy.yml). Both SSL
  # settings stay off on purpose. What that gives up is in docs/decisions.md, "Lab 13".
  #
  # assume_ssl: there is no SSL-terminating proxy in front of the app (kamal-proxy
  # runs with ssl: false), so the app must not pretend requests came over HTTPS.
  config.assume_ssl = false

  # force_ssl would redirect every request to https:// (where nothing answers),
  # send Strict-Transport-Security and mark the session cookie Secure, so the
  # browser would never send it back over http://. Signing in would be impossible.
  config.force_ssl = false

  # The address the app is reached at, e.g. "203.0.113.10". Unset while the image
  # is built and when production runs on a laptop.
  app_host = ENV["APP_HOST"].presence

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Links in emails open the app at its IP, over http:// (no https:// to send them to).
  config.action_mailer.default_url_options = { host: app_host || "localhost", protocol: "http" }

  # Emails go out through the SMTP provider. Everything about it lives in the
  # production credentials (config/credentials/production.yml.enc, unlocked on the
  # server by RAILS_MASTER_KEY), the password included. DigitalOcean blocks ports
  # 25, 465 and 587 on new droplets, so the port is one the provider also accepts
  # (2525). The sender is read from there too: ApplicationMailer uses smtp.from.
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
    address: Rails.application.credentials.dig(:smtp, :address),
    port: Rails.application.credentials.dig(:smtp, :port),
    user_name: Rails.application.credentials.dig(:smtp, :user_name),
    password: Rails.application.credentials.dig(:smtp, :password),
    authentication: :plain,
    enable_starttls_auto: true,
    open_timeout: 10,
    read_timeout: 10
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks: only requests
  # addressed to the droplet's IP are answered. kamal-proxy checks /up from inside
  # the server with another Host, so /up is left out of the check.
  if app_host
    config.hosts = [ app_host ]
    config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  end
end
