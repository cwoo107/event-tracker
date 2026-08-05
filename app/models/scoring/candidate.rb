module Scoring
  # One liaison's result from Ranking: their weighted score, the
  # per-criterion point breakdown (for the "score breakdown bars"), and any
  # hard-rule/load-hold violations (for the "manual override" warning).
  Candidate = Struct.new(:liaison, :score, :breakdown, :block_reasons, keyword_init: true) do
    def blocked?
      block_reasons.present?
    end
  end
end
