class LiaisonsController < ApplicationController
  before_action :set_liaison, only: %i[show edit update destroy]
  before_action :require_admin!, only: %i[new create destroy]
  before_action :authorize_edit!, only: %i[edit update]
  before_action :load_sidebar_liaisons, only: %i[index show new edit]

  def index
  end

  def show
  end

  def new
    @liaison = Liaison.new
    @liaison.build_user
  end

  # No password field in the form - a random one is set here so the
  # record can save, and the new liaison gets a real one via the same
  # password-reset email flow anyone else uses, rather than an admin
  # needing to invent and communicate a temporary one.
  def create
    @liaison = Liaison.new(liaison_params)
    @liaison.build_user unless @liaison.user
    @liaison.user.role = :liaison
    @liaison.user.password = SecureRandom.hex(20)

    if @liaison.save
      PasswordsMailer.reset(@liaison.user).deliver_later
      redirect_to liaison_path(@liaison), notice: "Liaison created - a password setup email has been sent."
    else
      load_sidebar_liaisons
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    permitted = Current.user.admin? ? liaison_params : self_service_liaison_params

    if @liaison.update(permitted)
      redirect_to liaison_path(@liaison), notice: "Profile updated."
    else
      load_sidebar_liaisons
      render :edit, status: :unprocessable_entity
    end
  end

  # Destroys the User, not the Liaison directly - User#has_one :liaison,
  # dependent: :destroy already cascades correctly, and removing the login
  # along with the profile is the right behavior for "this person is gone,"
  # as opposed to Activatable's active: false for "not taking assignments
  # right now."
  def destroy
    unless @liaison.destroyable?
      redirect_to liaison_path(@liaison),
                  alert: "#{@liaison.name} has assignment history and can't be deleted - deactivate them instead."
      return
    end

    @liaison.user.destroy
    redirect_to liaisons_path, notice: "Liaison removed."
  end

  private

  def set_liaison
    @liaison = Liaison.find(params[:id])
  end

  def require_admin!
    return if Current.user.admin?

    redirect_to liaisons_path, alert: "Only admins can do that."
  end

  def authorize_edit!
    return if Current.user.admin?
    return if @liaison.user_id == Current.user.id

    redirect_to liaisons_path, alert: "You can only edit your own profile."
  end

  # Active is admin-only, even on the self-service form - whether a
  # liaison is currently taking assignments is an operational decision,
  # not something to self-service alongside your own contact info.
  def liaison_params
    params.require(:liaison).permit(:region, :home_city, :color, :active, :skills_text,
                                     user_attributes: %i[name email_address])
  end

  def self_service_liaison_params
    params.require(:liaison).permit(:region, :home_city, :color, :skills_text,
                                     user_attributes: %i[name email_address])
  end

  def load_sidebar_liaisons
    @liaisons = Liaison.active.includes(:user).order(:region)
    @risk_assessment = RiskAssessment.new(pool: @liaisons)
  end
end
