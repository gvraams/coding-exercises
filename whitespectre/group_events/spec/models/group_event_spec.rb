require 'rails_helper'

def expect_fields_cant_be_blank(group_event)
  expect(group_event.valid?).to be(false)

  expect(group_event.errors.messages).to eq({
    start_date: ["can't be blank"],
    end_date: ["can't be blank"],
    duration: ["can't be blank"],
  })
end

RSpec.describe GroupEvent, type: :model do
  before(:all) do
    @gvraams = User.where(email: "gvraams@gmail.com").first

    unless @gvraams.present?
      @gvraams = create(:user, {
        uuid: SecureRandom.uuid,
        name: "Ram",
        password: "Ram",
        email: "Gvraams@gmail.com"
      })
    end

    @chennai = Location.where(name: "Chennai").first

    unless @chennai.present?
      @chennai = create(:location)
    end
  end

  context "validations" do
    it { should validate_presence_of(:uuid) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:location_id) }
    it { should validate_presence_of(:created_by_id) }
  end

  context "with two duration related fields set" do
    let(:group_event) { build(:group_event, {
      created_by: @gvraams,
      location: @chennai,
      start_date: nil,
      end_date: nil,
      duration: nil,
      status: "published",
    }) }

    it "validates presence of 3 duration related fields" do
      expect_fields_cant_be_blank(group_event)
    end

    it "computes end_date given start_date & duration" do
      expect_fields_cant_be_blank(group_event)

      group_event.start_date = 2.days.ago
      group_event.duration = 3.days

      expect(group_event.valid?).to be(true)
      expect(group_event.save).to be(true)
      expect(group_event.start_date.to_date).to eq(2.days.ago.to_date)
      expect(group_event.duration).to eq(3.days)
      expect(group_event.end_date.to_date).to eq(Time.zone.today)
    end

    it "computes start_date given end_date & duration" do
      expect_fields_cant_be_blank(group_event)

      group_event.duration = 3.days
      group_event.end_date = 5.days.from_now

      expect(group_event.valid?).to be(true)
      expect(group_event.save).to be(true)
      expect(group_event.duration).to eq(3.days)
      expect(group_event.start_date.to_date).to eq(3.days.from_now.to_date)
      expect(group_event.end_date.to_date).to eq(5.days.from_now.to_date)
    end

    it "computes duration given start_date & end_date" do
      expect_fields_cant_be_blank(group_event)

      group_event.start_date = 2.days.ago
      group_event.end_date = 5.days.from_now

      expect(group_event.valid?).to be(true)
      expect(group_event.save).to be(true)
      expect(group_event.duration).to eq(8.days)
      expect(group_event.start_date.to_date).to eq(2.days.ago.to_date)
      expect(group_event.end_date.to_date).to eq(5.days.from_now.to_date)
    end

    it "discards invalid duration given valid start_date & end_date" do
      expect_fields_cant_be_blank(group_event)

      group_event.start_date = 2.days.ago
      group_event.end_date = 5.days.from_now
      # Invalid duration considering start_date & end_date
      group_event.duration = 15

      expect(group_event.valid?).to be(true)
      expect(group_event.save).to be(true)
      # Duration is correctly calculated as 8 days
      expect(group_event.duration).to eq(8.days)
      expect(group_event.start_date.to_date).to eq(2.days.ago.to_date)
      expect(group_event.end_date.to_date).to eq(5.days.from_now.to_date)
    end
  end
end
