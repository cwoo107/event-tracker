module Scoring
  module Rules
    # "Never schedule a liaison for more than 3 events in a single week."
    class MaxWeeklyEvents
      def initialize(event, liaison, threshold:)
        @event = event
        @liaison = liaison
        @threshold = threshold
      end

      def violation
        return nil if @threshold.blank?

        count = @liaison.events_in_week(@event.starts_at).count
        return nil if count + 1 <= @threshold.to_i

        "would be the liaison's #{(count + 1).ordinalize} event this week (limit #{@threshold.to_i})"
      end
    end
  end
end
