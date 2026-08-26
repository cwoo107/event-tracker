# Shared by the three controllers behind the admin-only Account settings
# screen (AccountUsersController, EventTypesController,
# MaterialItemsController) - all render back into account_users/index, so
# they all need the same admin gate and the same full set of locals that
# view expects, whichever of them handles a given request.
module AccountSettingsScoped
  extend ActiveSupport::Concern

  MANAGEABLE_ROLES = %w[admin coordinator].freeze

  included do
    before_action :require_admin!
  end

  private

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

  # ||= throughout so a caller can set the one record it cares about
  # (e.g. an invalid @new_event_type, to show its error inline) before
  # calling this, without it being clobbered by the default here.
  def load_account_settings_locals
    @memberships ||= manageable_memberships
    @new_user ||= User.new
    @event_types ||= Current.account.event_types.order(:name)
    @new_event_type ||= EventType.new
    @material_items ||= Current.account.material_items.order(:name)
    @new_material_item ||= MaterialItem.new
  end

  # Re-renders the full account_users#index template so a request that
  # originated inside one of its catalog turbo frames (see
  # account_users/_catalog_section.html.erb) gets its error shown inline,
  # in place, without a full page redirect - Turbo Frames extract just the
  # matching frame from whatever HTML comes back, so the other sections
  # on the page are along for the ride but ignored.
  def render_account_settings_error
    load_account_settings_locals
    render "account_users/index", status: :unprocessable_entity
  end
end
