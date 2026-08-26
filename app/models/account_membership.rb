class AccountMembership < ApplicationRecord
  belongs_to :account
  belongs_to :user

  enum :role, { coordinator: 0, liaison: 1, admin: 2 }, default: :coordinator

  validates :user_id, uniqueness: { scope: :account_id }
end
