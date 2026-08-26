class EventTypesController < ApplicationController
  before_action :require_admin!
  before_action :set_event_type, only: %i[update destroy]

  def create
    event_type = Current.account.event_types.new(event_type_params)

    if event_type.save
      redirect_to account_users_path, notice: "#{event_type.name} added."
    else
      redirect_to account_users_path, alert: event_type.errors.full_messages.to_sentence
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
      redirect_to account_users_path, alert: "#{@event_type.name} is used by existing events - deactivate it instead."
    else
      @event_type.destroy
      redirect_to account_users_path, notice: "#{@event_type.name} removed."
    end
  end

  private

  def set_event_type
    @event_type = Current.account.event_types.find(params[:id])
  end

  def require_admin!
    return if Current.admin?

    redirect_to root_path, alert: "Only admins can do that."
  end

  def event_type_params
    params.require(:event_type).permit(:name)
  end
end
