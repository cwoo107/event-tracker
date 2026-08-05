module Scoring
  module Rules
    # "Cap weekend events at 12 per liaison per year." Shown unchecked
    # (disabled) by default in the Settings mockup - this only fires when
    # a coordinator has actually enabled it.
    class WeekendAnnualCap
      def initialize(event, liaison, threshold:)
        @event = event
        @liaison = liaison
        @threshold = threshold
      end

      def violation
        return nil if @threshold.blank?
        return nil unless @event.weekend?

        count = @liaison.weekend_events_ytd(reference_date: @event.starts_at.to_date)
        return nil if count + 1 <= @threshold.to_i

        "would be the liaison's #{(count + 1).ordinalize} weekend event this year (cap #{@threshold.to_i})"
      end
    end
  end
end
