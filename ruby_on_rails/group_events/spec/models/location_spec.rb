require 'rails_helper'

RSpec.describe Location, type: :model do
  context "validations" do
    it { should validate_presence_of(:uuid) }
    it { should validate_presence_of(:name) }
    it { should have_many(:group_events) }

    it "rejects duplicate uuid" do
      uuid = SecureRandom.uuid

      location1 = build(:location, {
        uuid: uuid,
        name: "Chennai",
      })

      expect(location1.valid?).to eq(true)
      expect(location1.save).to eq(true)

      location2 = build(:location, {
        uuid: uuid,
        name: "Bangalore",
      })

      expect(location2.valid?).to eq(false)
      expect(location2.errors.messages).to eq({ uuid: ["has already been taken"] })
    end
  end
end
