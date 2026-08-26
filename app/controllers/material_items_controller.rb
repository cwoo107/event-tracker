class MaterialItemsController < ApplicationController
  include AccountSettingsScoped

  before_action :set_material_item, only: %i[update destroy]

  def create
    @new_material_item = Current.account.material_items.new(material_item_params)

    if @new_material_item.save
      redirect_to account_users_path, notice: "#{@new_material_item.name} added."
    else
      render_account_settings_error
    end
  end

  def update
    @material_item.update!(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
    redirect_to account_users_path
  end

  def destroy
    if @material_item.event_material_items.any?
      @new_material_item = MaterialItem.new
      @new_material_item.errors.add(:base, "#{@material_item.name} is used by existing events - deactivate it instead.")
      render_account_settings_error
    else
      @material_item.destroy
      redirect_to account_users_path, notice: "#{@material_item.name} removed."
    end
  end

  private

  def set_material_item
    @material_item = Current.account.material_items.find(params[:id])
  end

  def material_item_params
    params.require(:material_item).permit(:name)
  end
end
