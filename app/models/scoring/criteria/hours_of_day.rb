module Scoring
  module Criteria
    # "Hours of day" (12%): "penalty for calls before 06:00 or ending after
    # 19:00", based on the implied departure/return time once the drive
    # from the office is factored in.
    #
    # Every liaison drives from the same office, so this is identical for
    # every candidate on a given event - it doesn't change the ranking
    # order, but it does affect the total score shown (and every candidate
    # gets the same, correctly, since the constraint is genuinely about the
    # event's own timing, not who's assigned).
    class HoursOfDay
      EARLY_CUTOFF_MINUTES = 6 * 60
      LATE_CUTOFF_MINUTES = 19 * 60

      def initialize(event, _liaison = nil)
        @event = event
      end

      def score
        value = 1.0
        value -= 0.5 if minutes_since_midnight(@event.implied_departure_time) < EARLY_CUTOFF_MINUTES
        value -= 0.5 if minutes_since_midnight(@event.implied_return_time) > LATE_CUTOFF_MINUTES
        value.clamp(0.0, 1.0)
      end

      private

      def minutes_since_midnight(time)
        (time.hour * 60) + time.min
      end
    end
  end
end
