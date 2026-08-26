# Mailgun via SMTP - no extra gem needed, ActionMailer's built-in :smtp
# delivery method talks to Mailgun's relay directly. Mailgun's SMTP
# username/password are generated separately from their API key (Sending
# domain -> SMTP credentials in the Mailgun dashboard), so don't reuse an
# API key here.
#
# Wrapped in to_prepare rather than run directly at the top level: this
# file references AppCredentials, which lives in app/models and is
# autoloaded - initializers run before eager loading/autoloading is
# guaranteed to be settled, so referencing an autoloaded constant directly
# here is unreliable (it broke server boot entirely, not just
# assets:precompile - both go through the same Rails.application.initialize!
# sequence). to_prepare is the hook Rails' own Autoloading Guide
# recommends for exactly this: code that depends on application classes
# but needs to run as part of initialization. It runs once after eager
# loading in production, and before every reload in development, so
# setting the same config repeatedly there is harmless.
#
# Every value here resolves through AppCredentials, which checks an
# environment variable first (set via a platform dashboard - Hatchbox,
# Heroku, etc. - no server access needed) before falling back to Rails
# encrypted credentials. Set whichever fits how you deploy:
#
#   MAILGUN_SMTP_DOMAIN=mg.yourdomain.com
#   MAILGUN_SMTP_USERNAME=postmaster@mg.yourdomain.com
#   MAILGUN_SMTP_PASSWORD=your-smtp-password
#   APP_HOST=events.yourdomain.com
#
# ...or, for local development, in Rails credentials:
#   mailgun:
#     domain: mg.yourdomain.com
#     smtp_username: postmaster@mg.yourdomain.com
#     smtp_password: your-smtp-password
#   app:
#     host: events.yourdomain.com
Rails.application.config.to_prepare do
  Rails.application.config.action_mailer.default_url_options = {
    host: AppCredentials.app_host || "localhost:3000",
    protocol: Rails.env.production? ? "https" : "http"
  }

  if Rails.env.production?
    Rails.application.config.action_mailer.delivery_method = :smtp
    Rails.application.config.action_mailer.perform_deliveries = true
    Rails.application.config.action_mailer.raise_delivery_errors = true
    Rails.application.config.action_mailer.smtp_settings = {
      address: "smtp.mailgun.org",
      port: 2525,
      domain: AppCredentials.mailgun_domain,
      user_name: AppCredentials.mailgun_smtp_username,
      password: AppCredentials.mailgun_smtp_password,
      authentication: :plain,
      enable_starttls_auto: true
    }
  end
end
