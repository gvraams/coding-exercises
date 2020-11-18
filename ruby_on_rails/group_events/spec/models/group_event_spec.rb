require 'rails_helper'

def expect_fields_cant_be_blank(group_event)
  expect(group_event.valid?).to be(false)

  expect(group_event.errors.messages).to eq({
    start_date: ["can't be blank"],
    end_date:   ["can't be blank"],
    duration:   ["can't be blank"],
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

  context "mandatory validations" do
    it { should validate_presence_of(:uuid) }
    it { should belong_to(:created_by) }
    it { should belong_to(:location) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  context "validations as published" do
    let(:group_event) {
      build(:group_event, {
        status: "published",
        name: nil,
        description: nil,
        start_date: nil,
        end_date: nil,
        duration: nil,
      })
    }

    it "validates presence of name, description, start_date, end_date & duration" do
      expect(group_event.valid?).to eq(false)

      expect(group_event.errors.messages).to eq({
        name:        ["can't be blank"],
        description: ["can't be blank"],
        start_date:  ["can't be blank"],
        end_date:    ["can't be blank"],
        duration:    ["can't be blank"],
      })
    end
  end

  context "with two duration related fields set" do
    let(:group_event) {
      build(:group_event, {
        created_by: @gvraams,
        location:   @chennai,
        start_date: nil,
        end_date:   nil,
        duration:   nil,
        status:     "published",
      })
    }

    it "validates presence of 3 duration related fields" do
      expect_fields_cant_be_blank(group_event)
    end

    it "computes end_date given start_date & duration" do
      expect_fields_cant_be_blank(group_event)

      group_event.assign_attributes({
        start_date: 2.days.from_now,
        duration:   3.days,
      })

      expect(group_event.valid?).to be(true)
      expect(group_event.save).to be(true)
      expect(group_event.start_date.to_date).to eq(2.days.from_now.to_date)
      expect(group_event.duration).to eq(3.days)
      expect(group_event.end_date.to_date).to eq(4.days.from_now.to_date)
    end

    it "computes start_date given end_date & duration" do
      expect_fields_cant_be_blank(group_event)

      group_event.assign_attributes({
        duration: 3.days,
        end_date: 5.days.from_now,
      })

      expect(group_event.valid?).to be(true)
      expect(group_event.save).to be(true)
      expect(group_event.duration).to eq(3.days)
      expect(group_event.start_date.to_date).to eq(3.days.from_now.to_date)
      expect(group_event.end_date.to_date).to eq(5.days.from_now.to_date)
    end

    it "computes duration given start_date & end_date" do
      expect_fields_cant_be_blank(group_event)

      group_event.assign_attributes({
        start_date: 2.days.from_now,
        end_date:   5.days.from_now,
      })

      expect(group_event.valid?).to be(true)
      expect(group_event.save).to be(true)
      expect(group_event.duration).to eq(4.days)
      expect(group_event.start_date.to_date).to eq(2.days.from_now.to_date)
      expect(group_event.end_date.to_date).to eq(5.days.from_now.to_date)
    end

    it "discards invalid duration given valid start_date & end_date" do
      expect_fields_cant_be_blank(group_event)

      group_event.assign_attributes({
        start_date: 2.days.from_now,
        end_date:   5.days.from_now,
        duration:   15.days, # Invalid duration considering given start_date & end_date
      })

      expect(group_event.valid?).to be(true)
      expect(group_event.save).to be(true)
      # Duration is correctly calculated as 4 days
      expect(group_event.duration).to eq(4.days)
      expect(group_event.start_date.to_date).to eq(2.days.from_now.to_date)
      expect(group_event.end_date.to_date).to eq(5.days.from_now.to_date)
    end

    it "rejects record with end_date > start_date" do
      group_event.assign_attributes({
        start_date: 5.days.from_now,
        end_date:   2.days.from_now,
      })

      expect(group_event.valid?).to be(false)
      expect(group_event.errors.messages).to eq({ base: ["End date cannot be lesser than start date"] })
    end

    it "rejects record with invalid duration" do
      group_event.assign_attributes({
        start_date: 2.days.from_now,
        duration: 0,
      })

      expect(group_event.valid?).to be(false)

      expect(group_event.errors.messages).to eq({
        duration: ["can't be blank"],
        end_date: ["can't be blank"],
      })

      group_event.assign_attributes({
        start_date: nil,
        duration: 0,
        end_date: 2.days.from_now,
      })

      expect(group_event.valid?).to be(false)

      expect(group_event.errors.messages).to eq({
        duration:   ["can't be blank"],
        start_date: ["can't be blank"],
      })
    end

    it "rejects record with start_date & end_date less than current time" do
      group_event.assign_attributes({
        start_date: 2.days.ago,
        end_date: 1.days.ago,
      })

      expect(group_event.valid?).to be(false)

      expect(group_event.errors.messages).to eq({
        start_date: ["Start date cannot be in the past"],
        end_date: ["End date cannot be in the past"],
      })
    end
  end

  context "soft deletion" do
    let(:group_event) { build(:group_event, {
      created_by: @gvraams,
      location: @chennai,
      start_date: 2.days.from_now,
      end_date: 3.days.from_now,
      status: "published",
    }) }

    it "soft deletes a record" do
      initial_count = GroupEvent.count

      expect(group_event.save).to eq(true)
      expect(GroupEvent.count).to eq(initial_count + 1)

      group_event.soft_destroy
      expect(GroupEvent.count).to eq(initial_count)
    end

    it "able to access deleted record using `with_soft_deleted` scope" do
      initial_count = GroupEvent.count

      expect(group_event.save).to eq(true)
      expect(GroupEvent.count).to eq(initial_count + 1)

      group_event.soft_destroy
      expect(GroupEvent.count).to eq(initial_count)
      expect(GroupEvent.with_soft_deleted.count).to eq(initial_count + 1)
    end

    it "able to access deleted record using `with_soft_deleted` block" do
      initial_count = GroupEvent.count

      expect(group_event.save).to eq(true)
      expect(GroupEvent.count).to eq(initial_count + 1)

      group_event.soft_destroy
      expect(GroupEvent.count).to eq(initial_count)

      SoftDeletable.with_soft_deleted do
        expect(GroupEvent.count).to eq(initial_count + 1)
      end
    end

    it "prevent record destruction unless marked for it" do
      initial_count = GroupEvent.count

      expect(group_event.save).to eq(true)
      expect(GroupEvent.count).to eq(initial_count + 1)

      expect(group_event.destroy).to eq(false)
      expect(GroupEvent.count).to eq(initial_count + 1)
    end

    it "destroys soft deleted record" do
      initial_count = GroupEvent.count

      expect(group_event.save).to eq(true)
      expect(GroupEvent.count).to eq(initial_count + 1)

      group_event.soft_destroy
      expect(GroupEvent.count).to eq(initial_count)
    end

    it "scopes :active, :soft_deleted, :with_soft_deleted" do
      initial_count = GroupEvent.count
      initial_soft_deleted_count = GroupEvent.soft_deleted.count

      expect(group_event.save).to eq(true)
      expect(GroupEvent.active.count).to eq(initial_count + 1)
      expect(GroupEvent.soft_deleted.count).to eq(initial_soft_deleted_count)

      group_event.soft_destroy
      expect(GroupEvent.active.count).to eq(initial_count)
      expect(GroupEvent.soft_deleted.count).to eq(initial_soft_deleted_count + 1)
      expect(GroupEvent.with_soft_deleted.count).to eq(initial_count + 1)
      expect(GroupEvent.count).to eq(initial_count)
    end
  end
end
