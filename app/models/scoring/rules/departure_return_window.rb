module Scoring
  module Rules
    # "Earliest departure from home 06:00; latest return 21:00." Backed by
    # two AssignmentRule rows (earliest_departure_minutes,
    # latest_return_minutes) since either can be enabled independently, but
    # checked together here since both read the same implied times.
    class DepartureReturnWindow
      def initialize(event, _liaison, earliest_departure_minutes:, latest_return_minutes:)
        @event = event
        @earliest = earliest_departure_minutes
        @latest = latest_return_minutes
      end

      def violation
        reasons = []
        reasons << departure_violation if @earliest.present? && departure_minutes < @earliest.to_i
        reasons << return_violation if @latest.present? && return_minutes > @latest.to_i
        reasons.presence&.join("; ")
      end

      private

      def departure_minutes
        minutes_since_midnight(@event.implied_departure_time)
      end

      def return_minutes
        minutes_since_midnight(@event.implied_return_time)
      end

      def minutes_since_midnight(time)
        (time.hour * 60) + time.min
      end

      def departure_violation
        "would depart before the #{format_time(@earliest.to_i)} earliest-departure rule"
      end

      def return_violation
        "would return after the #{format_time(@latest.to_i)} latest-return rule"
      end

      def format_time(minutes)
        format("%02d:%02d", minutes / 60, minutes % 60)
      end
    end
  end
end
