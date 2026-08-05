require "rails_helper"

RSpec.shared_examples "activatable" do
  let(:factory_name) { described_class.name.underscore.to_sym }
  let(:active_record) { create(factory_name, active: true) }
  let(:inactive_record) { create(factory_name, active: false) }

  it "scopes active records" do
    expect(described_class.active).to include(active_record)
    expect(described_class.active).not_to include(inactive_record)
  end

  it "scopes inactive records" do
    expect(described_class.inactive).to include(inactive_record)
    expect(described_class.inactive).not_to include(active_record)
  end

  it "deactivates" do
    expect { active_record.deactivate! }.to change(active_record, :active).to(false)
  end

  it "activates" do
    expect { inactive_record.activate! }.to change(inactive_record, :active).to(true)
  end
end

RSpec.describe Liaison, type: :model do
  it_behaves_like "activatable"
end

RSpec.describe MaterialItem, type: :model do
  it_behaves_like "activatable"
end
