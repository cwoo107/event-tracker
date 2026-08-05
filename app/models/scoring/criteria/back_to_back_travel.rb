module Scoring
  module Criteria
    # "Back-to-back travel" (8%): a soft penalty when this event is
    # long-haul (>= the configured mileage threshold) and the liaison
    # already has another long-haul assignment the day before or after.
    # The hard no_consecutive_long_haul_miles rule (when enabled) blocks
    # this outright; this criterion is what still matters if that rule is
    # disabled, or nudges the ranking near the threshold.
    class BackToBackTravel
      def initialize(event, liaison, long_haul_threshold_miles:)
        @event = event
        @liaison = liaison
        @threshold_miles = long_haul_threshold_miles
      end

      def score
        return 1.0 unless long_haul?(@event)

        adjacent_long_haul? ? 0.0 : 1.0
      end

      private

      def long_haul?(event)
        (event.drive_distance_miles || 0) >= @threshold_miles.to_f
      end

      def adjacent_long_haul?
        day_before = @event.starts_at.to_date - 1
        day_after = @event.starts_at.to_date + 1

        @liaison.long_haul_assignment_on(day_before, @threshold_miles) ||
          @liaison.long_haul_assignment_on(day_after, @threshold_miles)
      end
    end
  end
end
