class AccountUsersController < ApplicationController
  MANAGEABLE_ROLES = %w[admin coordinator].freeze

  before_action :require_admin!

  def index
    @new_user = User.new
    load_index_locals
  end

  # Inviting an email that already belongs to a User attaches a new
  # AccountMembership to them instead of failing on User's (still-global)
  # email uniqueness validation - that's how someone ends up belonging to
  # more than one account. A password-reset email only goes out for a
  # brand-new person; an existing user already has a password.
  def create
    role = params[:role]

    if MANAGEABLE_ROLES.exclude?(role)
      render_create_error(:role, "must be admin or coordinator")
      return
    end

    existing = User.find_by(email_address: user_params[:email_address])

    if existing
      attach_existing_user(existing, role)
    else
      invite_new_user(role)
    end
  end

  # Changes a teammate's role within this account only - never their own,
  # so an admin can't accidentally (or deliberately) demote themselves out
  # of a way to fix it. There's always at least one other admin (or none)
  # left able to change it back either way, same "self" guard as #destroy.
  def update
    membership = manageable_memberships.find(params[:id])

    if membership.user == Current.user
      redirect_to account_users_path, alert: "You can't change your own role."
    elsif MANAGEABLE_ROLES.exclude?(params[:role])
      redirect_to account_users_path, alert: "Role must be admin or coordinator."
    else
      membership.update!(role: params[:role])
      redirect_to account_users_path, notice: "#{membership.user.name} is now #{params[:role]}."
    end
  end

  # Removes this person's access to this account only - never the User
  # record itself, since they may belong to other accounts too. Historical
  # assignments/notes/activities they authored stay attached to the User
  # (dependent: :nullify was about deleting the login entirely, which this
  # no longer does). No separate "last admin" guard needed: only an admin
  # can reach this action (require_admin!), and that admin is never the
  # one being removed here (see below) - so there's always at least one
  # admin membership left on this account after this runs.
  def destroy
    membership = manageable_memberships.find(params[:id])

    if membership.user == Current.user
      redirect_to account_users_path, alert: "You can't remove your own access."
    else
      membership.destroy
      redirect_to account_users_path, notice: "#{membership.user.name} removed."
    end
  end

  private

  def attach_existing_user(user, role)
    if user.account_memberships.exists?(account: Current.account)
      render_create_error(:email_address, "already has access to this account")
      return
    end

    user.account_memberships.create!(account: Current.account, role: role)
    redirect_to account_users_path, notice: "#{user.name} added to this account."
  end

  def invite_new_user(role)
    @new_user = User.new(user_params)
    @new_user.password = SecureRandom.hex(20)

    if @new_user.save
      @new_user.account_memberships.create!(account: Current.account, role: role)
      PasswordsMailer.reset(@new_user).deliver_later
      redirect_to account_users_path, notice: "#{@new_user.name} added - a password setup email has been sent."
    else
      load_index_locals
      render :index, status: :unprocessable_entity
    end
  end

  def render_create_error(attribute, message)
    @new_user = User.new(user_params)
    @new_user.errors.add(attribute, message)
    load_index_locals
    render :index, status: :unprocessable_entity
  end

  def require_admin!
    return if Current.admin?

    redirect_to root_path, alert: "Only admins can do that."
  end

  # Scoped to admin/coordinator roles specifically, not just
  # Current.account.account_memberships, so this screen can never reach
  # (list, add, or remove) a liaison's login - those are managed entirely
  # through Liaisons.
  def manageable_memberships
    Current.account.account_memberships.where(role: MANAGEABLE_ROLES).includes(:user).order("users.name")
  end

  def load_index_locals
    @memberships = manageable_memberships
    @event_types = Current.account.event_types.order(:name)
    @new_event_type = EventType.new
    @material_items = Current.account.material_items.order(:name)
    @new_material_item = MaterialItem.new
  end

  def user_params
    params.require(:user).permit(:name, :email_address)
  end
end
