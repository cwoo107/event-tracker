# Lets an already-signed-in user spin up an additional account they'll
# run - distinct from RegistrationsController, which creates both a new
# Account AND a new User for someone who isn't signed in yet. Here the
# User already exists; this just adds an admin membership on a fresh
# Account and switches the current session over to it.
class AccountsController < ApplicationController
  include AccountSettingsScoped

  # Unlike the rest of this controller's actions, anyone signed in can
  # spin up a brand-new account for themselves (they become its admin) -
  # only #update, which edits the account they're already in, needs the
  # admin gate the concern adds by default.
  skip_before_action :require_admin!, only: %i[new create]

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

  # The current account's own profile - just the home office right now.
  # Renders back into account_users/index (its "Home office" section)
  # the same way EventTypesController/MaterialItemsController do, so a
  # validation error shows up inline rather than as a lost flash.
  def update
    if Current.account.update(office_params)
      redirect_to account_users_path, notice: "Home office updated."
    else
      render_account_settings_error
    end
  end

  private

  def account_params
    params.require(:account).permit(:name)
  end

  def office_params
    params.require(:account).permit(:office_address, :office_city, :office_state, :office_zip, :office_latitude, :office_longitude)
  end
end
