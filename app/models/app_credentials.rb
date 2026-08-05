# Each secret can come from either an environment variable - set through
# a platform dashboard (Hatchbox, Heroku, etc.) with no server access
# needed - or Rails encrypted credentials, which are more convenient for
# local development. The environment variable wins if both are set;
# neither is required to exist for the other to work.
module AppCredentials
  def self.mapbox_access_token
    ENV["MAPBOX_ACCESS_TOKEN"].presence || Rails.application.credentials.dig(:mapbox, :access_token)
  end

  def self.mailgun_domain
    ENV["MAILGUN_SMTP_DOMAIN"].presence || Rails.application.credentials.dig(:mailgun, :domain)
  end

  def self.mailgun_smtp_username
    ENV["MAILGUN_SMTP_USERNAME"].presence || Rails.application.credentials.dig(:mailgun, :smtp_username)
  end

  def self.mailgun_smtp_password
    ENV["MAILGUN_SMTP_PASSWORD"].presence || Rails.application.credentials.dig(:mailgun, :smtp_password)
  end

  def self.app_host
    ENV["APP_HOST"].presence || Rails.application.credentials.dig(:app, :host)
  end
end
