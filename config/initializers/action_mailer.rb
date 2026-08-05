# Mailgun via SMTP - no extra gem needed, ActionMailer's built-in :smtp
# delivery method talks to Mailgun's relay directly. Mailgun's SMTP
# username/password are generated separately from their API key (Sending
# domain -> SMTP credentials in the Mailgun dashboard), so don't reuse an
# API key here.
#
# Add to credentials (bin/rails credentials:edit):
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
    host: Rails.application.credentials.dig(:app, :host) || "localhost:3000",
    protocol: Rails.env.production? ? "https" : "http"
  }

  next unless Rails.env.production?

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
    address: "smtp.mailgun.org",
    port: 587,
    domain: Rails.application.credentials.dig(:mailgun, :domain),
    user_name: Rails.application.credentials.dig(:mailgun, :smtp_username),
    password: Rails.application.credentials.dig(:mailgun, :smtp_password),
    authentication: :plain,
    enable_starttls_auto: true
  }
end
