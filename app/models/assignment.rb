class Assignment < ApplicationRecord
  belongs_to :event
  belongs_to :liaison
  belongs_to :assigned_by, class_name: "User", optional: true

  enum :assignment_method, { auto: 0, manual: 1 }, prefix: true
  enum :assignment_status, { accepted: 0, declined: 1 }, prefix: true

  validates :score, numericality: true, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :recent_first, -> { order(created_at: :desc) }
end
