# Scoping the lookup to Current.user.accounts is the authorization check -
# a user can only switch into an account they actually belong to.
class AccountSwitchesController < ApplicationController
  def create
    account = Current.user.accounts.find(params[:account_id])
    Current.session.update!(account: account)
    redirect_to root_path, notice: "Switched to #{account.name}."
  end
end
