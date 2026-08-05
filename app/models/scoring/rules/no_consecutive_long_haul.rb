module Scoring
  module Rules
    # "No two long-haul (150 mi+) assignments on consecutive days."
    class NoConsecutiveLongHaul
      def initialize(event, liaison, threshold_miles:)
        @event = event
        @liaison = liaison
        @threshold_miles = threshold_miles
      end

      def violation
        return nil if @threshold_miles.blank?
        return nil unless long_haul?(@event)

        conflict = adjacent_long_haul_assignment
        return nil unless conflict

        "has another long-haul (#{@threshold_miles.to_i}mi+) assignment on " \
          "#{conflict.event.starts_at.strftime('%b %-d')}, the day before/after"
      end

      private

      def long_haul?(event)
        (event.drive_distance_miles || 0) >= @threshold_miles.to_f
      end

      def adjacent_long_haul_assignment
        day_before = @event.starts_at.to_date - 1
        day_after = @event.starts_at.to_date + 1

        @liaison.long_haul_assignment_on(day_before, @threshold_miles) ||
          @liaison.long_haul_assignment_on(day_after, @threshold_miles)
      end
    end
  end
end
