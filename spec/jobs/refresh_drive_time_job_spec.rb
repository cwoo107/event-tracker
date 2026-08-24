require "rails_helper"

RSpec.describe RefreshDriveTimeJob, type: :job do
  it "calls refresh_drive_time! on the event" do
    event = instance_double(Event)
    allow(Event).to receive(:find_by).with(id: 42).and_return(event)
    expect(event).to receive(:refresh_drive_time!)

    described_class.perform_now(42)
  end

  it "does nothing when the event no longer exists" do
    allow(Event).to receive(:find_by).with(id: -1).and_return(nil)

    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
