class ApplicationMailer < ActionMailer::Base
  MAILGUN_DOMAIN = AppCredentials.mailgun_domain || "usanmarketing.org"

  default from: "Event Tracker <notifications@#{MAILGUN_DOMAIN}>"
  layout "mailer"

  private

  # The display name only - the sending domain stays MAILGUN_DOMAIN
  # regardless of account, since that's infrastructure, not branding
  # (and has to match the domain Mailgun is configured to send as).
  # Falls back to the generic default from above when no account is
  # known (e.g. a password reset for a user with no account membership
  # left).
  def branded_from(account)
    return "Event Tracker <notifications@#{MAILGUN_DOMAIN}>" unless account

    "#{account.name} Event Tracker <notifications@#{MAILGUN_DOMAIN}>"
  end
end
