# Each secret can come from either an environment variable - set through
# a platform dashboard (Hatchbox, Heroku, etc.) with no server access
# needed - or Rails encrypted credentials, which are more convenient for
# local development. The environment variable wins if both are set;
# neither is required to exist for the other to work.
module AppCredentials
  def self.mapbox_access_token
    ENV["MAPBOX_ACCESS_TOKEN"].presence || Rails.application.credentials.dig(:mapbox, :access_token)
  end

  DOMAIN_PATTERN = /\A[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+\z/i

  # Sanitized so this is always safe to embed in a From/EHLO domain even
  # if the raw env var/credential has stray whitespace or was mistakenly
  # set to a full address (e.g. postmaster@mg.example.com) instead of a
  # bare domain - either broke SMTP with "cannot parse from address".
  def self.mailgun_domain
    raw = ENV["MAILGUN_SMTP_DOMAIN"].presence || Rails.application.credentials.dig(:mailgun, :domain)
    return nil unless raw

    domain = raw.to_s.strip
    domain = domain.split("@").last if domain.include?("@")

    unless domain.match?(DOMAIN_PATTERN)
      Rails.logger.warn("AppCredentials.mailgun_domain: #{raw.inspect} doesn't look like a valid domain (sanitized to #{domain.inspect}) - ignoring it")
      return nil
    end

    domain
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
