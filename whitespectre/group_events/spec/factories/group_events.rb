FactoryBot.define do
  factory :group_event do
    uuid { SecureRandom.uuid }
    name { "Name" }
    description { "Description" }
    created_by { FactoryBot.create(:user) }
    location { FactoryBot.create(:location) }
    start_date { 2.days.ago }
    end_date { 3.days.from_now }
    duration { nil }
    status { nil }
  end
end
