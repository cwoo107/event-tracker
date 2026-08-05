class Activity < ApplicationRecord
  belongs_to :subject, polymorphic: true
  belongs_to :actor, class_name: "User", optional: true

  validates :action, presence: true

  scope :recent_first, -> { order(created_at: :desc) }
end
