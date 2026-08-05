module Scoring
  module Criteria
    # "Weekend weighting" (18%): "a Saturday or Sunday event counts as
    # 1.5x toward the weekly load" - here, toward a YTD weekend-load
    # comparison against the team average, distinct from the plain
    # per-week count WeeklyLoadBalance already covers.
    #
    # Neutral (0.5) for weekday events, since this criterion has nothing to
    # say about them. For weekend events: 1.0 at zero weighted weekend load,
    # 0.5 at the team average, 0.0 at double the average or beyond.
    class WeekendWeighting
      WEEKEND_MULTIPLIER = 1.5

      def initialize(event, liaison, team_average_weekend_load:)
        @event = event
        @liaison = liaison
        @team_average_weekend_load = team_average_weekend_load
      end

      def score
        return 0.5 unless @event.weekend?
        return 1.0 if @team_average_weekend_load.to_f <= 0

        ratio = weighted_weekend_load / @team_average_weekend_load
        (1.0 - (ratio / 2.0)).clamp(0.0, 1.0)
      end

      def weighted_weekend_load
        @liaison.weekend_events_ytd(reference_date: @event.starts_at.to_date) * WEEKEND_MULTIPLIER
      end
    end
  end
end
