class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
  delegate :account, to: :session, allow_nil: true

  # This user's role/permissions within whichever account is currently
  # active - a user can be an admin in one account and a coordinator in
  # another, so role lives on the membership, not on User itself.
  #
  # Deliberately NOT memoized onto a bare @ivar: CurrentAttributes#reset
  # (called between requests) only clears state declared via `attribute`,
  # not plain instance variables - a bare @membership ||= here would leak
  # one request's admin/liaison status into the next request handled by
  # the same thread.
  def membership
    user&.account_memberships&.find_by(account: account)
  end

  # This user's Liaison profile for the currently active account, if any
  # - a user can have one Liaison profile per account (Liaison belongs_to
  # both :account and :user). Not memoized, same reasoning as #membership.
  def liaison
    user&.liaisons&.find_by(account: account)
  end

  delegate :role, :admin?, :coordinator?, :liaison?, to: :membership, allow_nil: true
end
