class PasswordsMailer < ApplicationMailer
  # account: which of the user's (possibly several) accounts this reset is
  # in the context of - callers that know (inviting a teammate, adding a
  # liaison) pass Current.account explicitly; self-service "forgot
  # password" doesn't know, so it falls back to whichever account the
  # user joined first.
  def reset(user, account: user.accounts.order(:created_at).first)
    @user = user
    @account = account

    mail subject: "Reset your password", to: user.email_address, from: branded_from(@account)
  end
end
