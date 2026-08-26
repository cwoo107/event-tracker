class EventTypesController < ApplicationController
  include AccountSettingsScoped

  before_action :set_event_type, only: %i[update destroy]

  def create
    @new_event_type = Current.account.event_types.new(event_type_params)

    if @new_event_type.save
      redirect_to account_users_path, notice: "#{@new_event_type.name} added."
    else
      render_account_settings_error
    end
  end

  # The only field a row's own form submits is the active toggle - renaming
  # would need its own inline edit affordance, not needed yet.
  def update
    @event_type.update!(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
    redirect_to account_users_path
  end

  def destroy
    if @event_type.events.any?
      @new_event_type = EventType.new
      @new_event_type.errors.add(:base, "#{@event_type.name} is used by existing events - deactivate it instead.")
      render_account_settings_error
    else
      @event_type.destroy
      redirect_to account_users_path, notice: "#{@event_type.name} removed."
    end
  end

  private

  def set_event_type
    @event_type = Current.account.event_types.find(params[:id])
  end

  def event_type_params
    params.require(:event_type).permit(:name)
  end
end
