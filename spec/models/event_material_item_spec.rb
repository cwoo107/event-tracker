require "rails_helper"

RSpec.describe EventMaterialItem, type: :model do
  it { is_expected.to validate_uniqueness_of(:material_item_id).scoped_to(:event_id) }

  describe "#check! and #uncheck!" do
    it "records who checked the item and when" do
      item = create(:event_material_item)
      staffer = create(:user)

      item.check!(by: staffer)
      expect(item.reload).to be_checked
      expect(item.checked_by).to eq(staffer)
      expect(item.checked_at).to be_present

      item.uncheck!
      expect(item.reload).not_to be_checked
      expect(item.checked_by).to be_nil
      expect(item.checked_at).to be_nil
    end
  end
end
