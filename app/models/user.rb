class User < ApplicationRecord
  include Initialing

  has_secure_password
  # Stateless, signed, self-expiring tokens - no separate reset_token
  # column to store/clean up. Salted with a slice of the current
  # password_digest so a token is automatically invalidated the moment the
  # password actually changes (including by using the token itself), on
  # top of the 15-minute expiry.
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_digest&.last(10)
  end

  has_many :sessions, dependent: :destroy
  has_one :liaison, dependent: :destroy

  has_many :assignments_made, class_name: "Assignment", foreign_key: :assigned_by_id,
                               inverse_of: :assigned_by, dependent: :nullify
  has_many :notes, foreign_key: :author_id, inverse_of: :author, dependent: :nullify
  has_many :activities, foreign_key: :actor_id, inverse_of: :actor, dependent: :nullify

  enum :role, { coordinator: 0, liaison: 1, admin: 2 }, default: :coordinator

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true

  # "Caleb B." style short form used in the nav header
  def short_name
    first, *rest = name.split
    [first, rest.last&.first&.+(".")].compact.join(" ")
  end
end
