module Scoring
  module Criteria
    # "Weekly load balance" (22%): how far the liaison sits from the
    # org-wide weekly pacing target (AssignmentSetting#weekly_target, e.g.
    # 2/week) for the specific week this event falls in.
    #
    # score: 1.0 with zero events that week, dropping linearly to 0.0 once
    # already at (or past) the target - separate from the hard
    # max_weekly_events cap, which allows going slightly over.
    class WeeklyLoadBalance
      def initialize(event, liaison, weekly_target:)
        @event = event
        @liaison = liaison
        @weekly_target = weekly_target
      end

      def score
        return 1.0 if @weekly_target.to_i <= 0

        count = @liaison.events_in_week(@event.starts_at).count
        (1.0 - (count.to_f / @weekly_target)).clamp(0.0, 1.0)
      end
    end
  end
end
