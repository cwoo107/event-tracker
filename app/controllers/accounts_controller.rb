# Lets an already-signed-in user spin up an additional account they'll
# run - distinct from RegistrationsController, which creates both a new
# Account AND a new User for someone who isn't signed in yet. Here the
# User already exists; this just adds an admin membership on a fresh
# Account and switches the current session over to it.
class AccountsController < ApplicationController
  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)

    ActiveRecord::Base.transaction do
      @account.save!
      @account.account_memberships.create!(user: Current.user, role: :admin)
      @account.seed_defaults!
    end

    Current.session.update!(account: @account)
    redirect_to root_path, notice: "#{@account.name} created - you're now working in it."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def account_params
    params.require(:account).permit(:name)
  end
end
