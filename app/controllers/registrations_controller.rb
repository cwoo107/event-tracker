class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @account = Account.new
    @user = User.new
  end

  def create
    @account = Account.new(account_params)
    @user = @account.users.new(user_params.merge(role: :admin))

    ActiveRecord::Base.transaction do
      @account.save!
      @user.save!
      @account.seed_defaults!
    end

    start_new_session_for(@user)
    redirect_to root_path, notice: "Welcome! Your account is ready."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def account_params
    params.require(:account).permit(
      :name, :office_address, :office_city, :office_state, :office_zip, :office_latitude, :office_longitude
    )
  end

  def user_params
    params.require(:user).permit(:name, :email_address, :password)
  end
end
