require "rails_helper"

RSpec.describe SendEventRemindersJob, type: :job do
  let(:account) { create(:account) }

  def assignment_for(starts_at)
    event = create(:event, account: account, starts_at: starts_at, ends_at: starts_at + 2.hours)
    create(:assignment, event: event)
  end

  it "emails liaisons assigned to events starting tomorrow and marks them reminded" do
    tomorrow_assignment = assignment_for(1.day.from_now.change(hour: 10))
    assignment_for(2.days.from_now.change(hour: 10)) # not due yet
    assignment_for(Time.current.change(hour: 10) + 1.hour) # today, not tomorrow

    expect { described_class.perform_now }
      .to have_enqueued_mail(LiaisonMailer, :event_reminder).with(tomorrow_assignment)

    expect(tomorrow_assignment.reload.reminder_sent_at).to be_present
  end

  it "does not re-send a reminder that already went out" do
    assignment = assignment_for(1.day.from_now.change(hour: 10))
    assignment.update!(reminder_sent_at: 1.hour.ago)

    expect { described_class.perform_now }.not_to have_enqueued_mail(LiaisonMailer, :event_reminder)
  end

  it "skips an assignment that's no longer active" do
    assignment = assignment_for(1.day.from_now.change(hour: 10))
    assignment.update!(active: false)

    expect { described_class.perform_now }.not_to have_enqueued_mail(LiaisonMailer, :event_reminder)
  end
end
