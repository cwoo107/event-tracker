module Scoring
  module Rules
    # "Block same-day round trips over 3 hours each way - require an
    # approved overnight." Liaison-invariant (same drive from the office
    # for everyone) but still evaluated per-candidate so it surfaces
    # consistently in the explanation panel regardless of who's picked.
    class OvernightApproval
      def initialize(event, _liaison, threshold_hours:)
        @event = event
        @threshold_hours = threshold_hours
      end

      def violation
        return nil if @threshold_hours.blank?
        return nil if @event.overnight_approved?
        return nil if (@event.drive_time_minutes || 0) <= @threshold_hours.to_f * 60

        "one-way drive (#{@event.drive_time_minutes} min) exceeds the #{@threshold_hours.to_f}h " \
          "same-day threshold without an approved overnight"
      end
    end
  end
end
