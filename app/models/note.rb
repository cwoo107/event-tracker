class Note < ApplicationRecord
  belongs_to :event
  belongs_to :author, class_name: "User"

  validates :body, presence: true

  scope :recent_first, -> { order(created_at: :desc) }
end
