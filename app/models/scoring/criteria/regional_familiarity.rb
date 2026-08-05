module Scoring
  module Criteria
    # "Regional familiarity" (10%): "prior events with the same requester
    # or county". A direct relationship with the requesting organization is
    # the stronger signal; a shared county without that is weaker but still
    # counts. Binary-ish by design for v1 - a count-weighted version would
    # need more product input on what "more familiar" should mean.
    class RegionalFamiliarity
      ORGANIZATION_MATCH_SCORE = 1.0
      COUNTY_MATCH_SCORE = 0.6
      NO_MATCH_SCORE = 0.0

      def initialize(event, liaison)
        @event = event
        @liaison = liaison
      end

      def score
        return ORGANIZATION_MATCH_SCORE if prior_events_for_organization?
        return COUNTY_MATCH_SCORE if prior_events_in_county?

        NO_MATCH_SCORE
      end

      private

      def prior_events
        @liaison.events.where.not(id: @event.id)
      end

      def prior_events_for_organization?
        return false if @event.requester_organization.blank?

        prior_events.where("LOWER(requester_organization) = ?", @event.requester_organization.downcase).exists?
      end

      def prior_events_in_county?
        return false if @event.county.blank?

        prior_events.where(county: @event.county).exists?
      end
    end
  end
end
