module Scoring
  module Criteria
    # "Drive time from HQ" (30%). Every liaison drives from the same office,
    # so this event's own drive time can't distinguish candidates - what
    # does is how much cumulative drive burden each liaison is already
    # carrying this year. A liaison below the team average is favored for
    # another drive-heavy event; one well above it is not, to spread the
    # physical travel load and reduce fatigue.
    #
    # score: 1.0 at zero cumulative hours, 0.5 at the team average,
    # 0.0 at double the team average or beyond.
    class DriveTime
      def initialize(event, liaison, team_average_hours:)
        @event = event
        @liaison = liaison
        @team_average_hours = team_average_hours
      end

      def score
        return 1.0 if @team_average_hours.to_f <= 0

        ratio = @liaison.ytd_drive_hours(reference_date: @event.starts_at.to_date) / @team_average_hours
        (1.0 - (ratio / 2.0)).clamp(0.0, 1.0)
      end
    end
  end
end
