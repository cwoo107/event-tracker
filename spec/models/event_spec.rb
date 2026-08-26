require "rails_helper"

RSpec.describe Event, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }

    it "allows blank requester fields" do
      event = build(:event, requester_name: nil, requester_email: nil, requester_organization: nil)

      expect(event).to be_valid
    end

    it "requires ends_at after starts_at" do
      event = build(:event, starts_at: Time.zone.now, ends_at: Time.zone.now - 1.hour)

      expect(event).not_to be_valid
      expect(event.errors[:ends_at]).to include("must be after the start time")
    end
  end

  describe "#duration_minutes" do
    it "computes minutes between start and end" do
      event = build(:event, starts_at: Time.zone.parse("2026-08-01 09:00"), ends_at: Time.zone.parse("2026-08-01 11:30"))
      expect(event.duration_minutes).to eq(150)
    end
  end

  describe "#prep_starts_at and #teardown_ends_at" do
    it "pads the on-site window with prep and teardown time" do
      event = build(:event,
        starts_at: Time.zone.parse("2026-08-01 09:00"),
        ends_at: Time.zone.parse("2026-08-01 11:00"),
        prep_minutes: 45,
        teardown_minutes: 20)

      expect(event.prep_starts_at).to eq(Time.zone.parse("2026-08-01 08:15"))
      expect(event.teardown_ends_at).to eq(Time.zone.parse("2026-08-01 11:20"))
    end
  end

  describe "#weekend?" do
    it "is true for Saturday events" do
      expect(build(:event, :weekend)).to be_weekend
    end

    it "is false for weekday events" do
      event = build(:event, starts_at: Time.zone.parse("2026-08-03 09:00")) # a Monday
      expect(event).not_to be_weekend
    end
  end

  describe "#drive_time_minutes and #drive_distance_miles" do
    it "converts stored seconds and meters to display units" do
      event = build(:event, drive_time_seconds: 5400, drive_distance_meters: 80_467)

      expect(event.drive_time_minutes).to eq(90)
      expect(event.drive_distance_miles).to eq(50.0)
    end

    it "returns nil when not yet calculated" do
      event = build(:event, drive_time_seconds: nil, drive_distance_meters: nil)

      expect(event.drive_time_minutes).to be_nil
      expect(event.drive_distance_miles).to be_nil
    end
  end

  describe "#refresh_drive_time!" do
    it "persists distance, time, and route geometry from Mapbox" do
      event = create(:event)
      geometry = { "type" => "LineString", "coordinates" => [ [ -122.0247, 38.0116 ], [ -121.4944, 38.5816 ] ] }
      route = instance_double(Geocoding::DriveRoute, found?: true, distance_meters: 80_467, duration_seconds: 5400, geometry: geometry)
      allow(Geocoding::DriveRoute).to receive(:new)
        .with(origin: event.account.office_location, destination: event.location, arrive_by: event.starts_at - Event::DRIVE_ARRIVAL_BUFFER)
        .and_return(route)

      event.refresh_drive_time!

      expect(event.reload.drive_distance_meters).to eq(80_467)
      expect(event.drive_time_seconds).to eq(5400)
      expect(event.drive_route_geometry).to eq(geometry)
    end

    it "leaves the event unchanged when Mapbox has no route" do
      event = create(:event)
      route = instance_double(Geocoding::DriveRoute, found?: false)
      allow(Geocoding::DriveRoute).to receive(:new).and_return(route)

      event.refresh_drive_time!

      expect(event.reload.drive_distance_meters).to be_nil
      expect(event.drive_route_geometry).to be_nil
    end

    it "does nothing when the account hasn't set a home office location yet" do
      account = create(:account, office_latitude: nil, office_longitude: nil)
      event = create(:event, account: account)
      expect(Geocoding::DriveRoute).not_to receive(:new)

      event.refresh_drive_time!

      expect(event.reload.drive_distance_meters).to be_nil
    end
  end

  describe "#requires_second_liaison?" do
    it "is true above the co-staffing attendee threshold" do
      create(:assignment_rule, key: "co_staffing_attendee_threshold", threshold: 500)
      expect(build(:event, estimated_attendees: 600)).to be_requires_second_liaison
      expect(build(:event, estimated_attendees: 200)).not_to be_requires_second_liaison
    end

    it "falls back to 500 when the rule isn't configured" do
      expect(build(:event, estimated_attendees: 501)).to be_requires_second_liaison
    end
  end

  describe "#assign_to!" do
    it "creates an assignment record, adds the liaison, and logs an activity" do
      event = create(:event)
      liaison = create(:liaison)
      admin = create(:user, :admin)

      expect {
        event.assign_to!(liaison, by: admin, assignment_method: :auto, score: 91.2, score_breakdown: { "drive_time" => 40 })
      }.to change(event.assignments, :count).by(1)
        .and change(event.activities, :count).by(1)

      event.reload
      expect(event.liaisons).to contain_exactly(liaison)
      expect(event).to be_assigned
      expect(event.assignments.last).to be_assignment_method_auto
    end

    it "supports co-staffing a large event with a second liaison" do
      event = create(:event, estimated_attendees: 600)
      lead = create(:liaison)
      co_liaison = create(:liaison)
      admin = create(:user, :admin)

      event.assign_to!(lead, by: admin)
      event.assign_to!(co_liaison, by: admin)

      expect(event.reload.liaisons).to contain_exactly(lead, co_liaison)
      expect(event).to be_co_staffed
      expect(event).to be_fully_staffed
    end
  end

  describe "#unassign!" do
    it "clears the liaison and logs an activity" do
      event = create(:event, :assigned)
      admin = create(:user, :admin)

      expect { event.unassign!(by: admin) }.to change(event.activities, :count).by(1)

      event.reload
      expect(event.liaisons).to be_empty
      expect(event).to be_unassigned
    end

    it "can remove just one liaison from a co-staffed event, leaving the other active" do
      event = create(:event)
      lead = create(:liaison)
      co_liaison = create(:liaison)
      admin = create(:user, :admin)
      event.assign_to!(lead, by: admin)
      event.assign_to!(co_liaison, by: admin)

      event.unassign!(by: admin, liaison: co_liaison)

      expect(event.reload.liaisons).to contain_exactly(lead)
      expect(event).to be_assigned
    end
  end

  describe "#reassign_to!" do
    it "swaps the active liaison for a new one" do
      event = create(:event, :assigned)
      original_liaison = event.liaisons.first
      new_liaison = create(:liaison)
      admin = create(:user, :admin)

      event.reassign_to!(new_liaison, by: admin)

      event.reload
      expect(event.liaisons).to contain_exactly(new_liaison)
      expect(event.assignments.where(liaison: original_liaison).last).not_to be_active
    end
  end

  describe "#complete!" do
    it "marks the event completed and logs an activity" do
      event = create(:event, :assigned)
      admin = create(:user, :admin)

      expect { event.complete!(by: admin) }.to change(event.activities, :count).by(1)
      expect(event.reload).to be_completed
    end
  end

  describe ".weekend" do
    it "returns only events occurring on a Saturday or Sunday" do
      weekend_event = create(:event, :weekend)
      weekday_event = create(:event, starts_at: Time.zone.parse("2026-08-03 09:00"), ends_at: Time.zone.parse("2026-08-03 11:00"))

      expect(Event.weekend).to include(weekend_event)
      expect(Event.weekend).not_to include(weekday_event)
    end
  end
end
