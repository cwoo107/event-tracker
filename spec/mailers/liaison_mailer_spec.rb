require "rails_helper"

RSpec.describe LiaisonMailer, type: :mailer do
  describe "#event_reminder" do
    let(:account) { create(:account) }
    let(:assignment) { create(:assignment, event: event) }
    let(:event) do
      create(:event, account: account, starts_at: 1.day.from_now.change(hour: 10),
                      ends_at: 1.day.from_now.change(hour: 12), venue_name: "Grange Hall", city: "Elk Grove")
    end
    let(:mail) { described_class.event_reminder(assignment) }

    it "addresses the liaison with a subject naming the event" do
      expect(mail.to).to eq([ assignment.liaison.email_address ])
      expect(mail.subject).to include(event.title)
      expect(mail.subject).to include("tomorrow")
    end

    it "includes a Google Maps driving directions link to the event" do
      expect(mail.html_part.body.to_s).to include(ERB::Util.html_escape(event.google_maps_directions_url))
      expect(mail.text_part.body.to_s).to include(event.google_maps_directions_url)
    end

    it "lists the event's location and arrival time" do
      expect(mail.html_part.body.to_s).to include("Grange Hall")
      expect(mail.html_part.body.to_s).to include(event.prep_starts_at.strftime("%-I:%M %p"))
    end

    it "brands the from name and footer with the account's own name" do
      expect(mail["from"].value).to eq("#{account.name} Event Tracker <notifications@usanmarketing.org>")
      expect(mail.html_part.body.to_s).to include(account.name)
      expect(mail.html_part.body.to_s).not_to include("USAN")
    end

    context "without an office location on the account" do
      let(:account) { create(:account, office_latitude: nil, office_longitude: nil) }

      it "still links directions, just without an origin" do
        expect(event.google_maps_directions_url).not_to include("origin=")
        expect(mail.html_part.body.to_s).to include("Get driving directions")
      end
    end
  end
end
