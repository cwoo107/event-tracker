# Shared by any model with a simple on/off lifecycle (Liaison, MaterialItem).
# Kept intentionally tiny - this is the one piece of behavior that's
# genuinely duplicated across models today. Per-model logic (e.g. Event's
# scheduling and assignment methods) stays on the model itself rather than
# being split into single-use concerns.
module Activatable
  extend ActiveSupport::Concern

  included do
    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
  end

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end
end
