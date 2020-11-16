require 'rails_helper'

RSpec.describe User, type: :model do
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
  end

  context "validations" do
    it { should validate_presence_of(:uuid) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
  end

  context "rejects invalid email" do
    invalid_emails = [
      "gvraams@gmail",
      "@gmail.com",
      "gmail.com",
      "com",
      "a@.b",
      "a@b.",
      "@a.b",
    ]

    invalid_emails.each do |invalid_email|
      it "Invalid email check" do
        user = User.new({
          uuid: SecureRandom.uuid,
          name: "Gvraams",
          email: invalid_email,
          password: "password",
        })

        expect(user.valid?).to eq(false)
        expect(user.errors.messages).to eq({ email: ["is invalid"] })
      end
    end
  end

  it "accepts valid email" do
    user = build(:user, {
      email: "gvraams2@gmail.com",
    })

    expect(user.valid?).to eq(true)
    expect(user.save).to eq(true)
    expect(user.email).to eq("gvraams2@gmail.com")
  end

  it "downcases email" do
    expect(@gvraams.email).to eq("gvraams@gmail.com")
  end

  it "rejects duplicate email" do
    duplicate_user = build(:user, {
      email: "gvraams@gmail.com",
    })

    expect(duplicate_user.valid?).to eq(false)
    expect(duplicate_user.errors.messages).to eq({ email: ["has already been taken"] })

    duplicate_user = build(:user, {
      email: "Gvraams@gmail.com",
    })

    expect(duplicate_user.valid?).to eq(false)
    expect(duplicate_user.errors.messages).to eq({ email: ["has already been taken"] })
  end

  it "rejects duplicate uuid" do
    duplicate_user = build(:user, {
      uuid: @gvraams.uuid,
      email: "gvraams2@gmail.com",
    })

    expect(duplicate_user.valid?).to eq(false)
    expect(duplicate_user.errors.messages).to eq({ uuid: ["has already been taken"] })
  end
end
