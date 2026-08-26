class MaterialItemsController < ApplicationController
  before_action :require_admin!
  before_action :set_material_item, only: %i[update destroy]

  def create
    material_item = Current.account.material_items.new(material_item_params)

    if material_item.save
      redirect_to account_users_path, notice: "#{material_item.name} added."
    else
      redirect_to account_users_path, alert: material_item.errors.full_messages.to_sentence
    end
  end

  def update
    @material_item.update!(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
    redirect_to account_users_path
  end

  def destroy
    if @material_item.event_material_items.any?
      redirect_to account_users_path, alert: "#{@material_item.name} is used by existing events - deactivate it instead."
    else
      @material_item.destroy
      redirect_to account_users_path, notice: "#{@material_item.name} removed."
    end
  end

  private

  def set_material_item
    @material_item = Current.account.material_items.find(params[:id])
  end

  def require_admin!
    return if Current.admin?

    redirect_to root_path, alert: "Only admins can do that."
  end

  def material_item_params
    params.require(:material_item).permit(:name)
  end
end
