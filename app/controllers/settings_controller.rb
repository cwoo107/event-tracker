class SettingsController < ApplicationController
  def edit
    @form = SettingsForm.load(Current.account)
  end

  def update
    @form = SettingsForm.load(Current.account)

    if @form.save(settings_params, account: Current.account, updated_by: Current.user)
      redirect_to edit_settings_path, notice: "Settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def reset
    SettingsForm.reset_to_defaults!(account: Current.account, updated_by: Current.user)
    redirect_to edit_settings_path, notice: "Restored default weights and rules."
  end

  private

  def settings_params
    params.permit(
      :work_weeks_per_year, :weekly_target,
      weights: ScoringWeight::CRITERIA,
      rules: AssignmentRule::KEYS.keys.index_with { [:enabled] },
      risk_thresholds: RiskThreshold::DEFAULTS.keys.index_with { %i[enabled multiplier] }
    )
  end
end
