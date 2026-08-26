class ApplicationMailer < ActionMailer::Base
  default from: "Event Tracker <notifications@usanmarketing.org>"
  layout "mailer"

  private

  # The display name only - notifications@usanmarketing.org stays the
  # sending domain regardless of account, since that's infrastructure,
  # not branding. Falls back to the generic default from above when no
  # account is known (e.g. a password reset for a user with no account
  # membership left).
  def branded_from(account)
    return "Event Tracker <notifications@usanmarketing.org>" unless account

    "#{account.name} Event Tracker <notifications@usanmarketing.org>"
  end
end
