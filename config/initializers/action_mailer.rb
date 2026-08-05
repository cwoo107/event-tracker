# Mailgun via SMTP - no extra gem needed, ActionMailer's built-in :smtp
# delivery method talks to Mailgun's relay directly. Mailgun's SMTP
# username/password are generated separately from their API key (Sending
# domain -> SMTP credentials in the Mailgun dashboard), so don't reuse an
# API key here.
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
#
# This is a dedicated initializer rather than edits to
# config/environments/production.rb directly - those files already exist
# from `rails new` and aren't part of this deliverable, so this avoids
# guessing at their current contents and risking overwriting something.
Rails.application.configure do
  config.action_mailer.default_url_options = {
    host: AppCredentials.app_host || "localhost:3000",
    protocol: Rails.env.production? ? "https" : "http"
  }

  next unless Rails.env.production?

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
    address: "smtp.mailgun.org",
    port: 587,
    domain: AppCredentials.mailgun_domain,
    user_name: AppCredentials.mailgun_smtp_username,
    password: AppCredentials.mailgun_smtp_password,
    authentication: :plain,
    enable_starttls_auto: true
  }
end
