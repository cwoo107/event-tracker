class EventMaterialItem < ApplicationRecord
  belongs_to :event
  belongs_to :material_item
  belongs_to :checked_by, class_name: "User", optional: true

  validates :quantity, numericality: { greater_than: 0 }
  validates :material_item_id, uniqueness: { scope: :event_id }

  def check!(by:)
    update!(checked: true, checked_at: Time.current, checked_by: by)
  end

  def uncheck!
    update!(checked: false, checked_at: nil, checked_by: nil)
  end
end
