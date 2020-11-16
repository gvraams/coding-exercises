require 'rails_helper'

RSpec.describe Location, type: :model do
  it "has a name" do
    location_id = SecureRandom.uuid

    location = build(:location, {
      uuid: location_id,
      name: nil
    })

    expect(location.valid?).to be(false)
    expect(location.errors.messages).to eq({ name: ["can't be blank"] })

    location.name = "Chennai"

    expect(location.valid?).to be(true)
    expect(location.save).to be(true)
    expect(location.uuid).to eq(location_id)
  end

  it "has a UUID" do
    location_id = nil

    location = build(:location, {
      uuid: nil,
      name: "Chennai"
    })

    expect(location.valid?).to be(false)
    expect(location.errors.messages).to eq({ uuid: ["can't be blank"] })

    location_id = SecureRandom.uuid
    location.uuid = location_id

    expect(location.valid?).to be(true)
    expect(location.save).to be(true)
    expect(location.uuid).to eq(location_id)
  end

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
      name: "Chennai",
    })

    expect(location2.valid?).to eq(false)
    expect(location2.errors.messages).to eq({ uuid: ["has already been taken"] })
  end
end
