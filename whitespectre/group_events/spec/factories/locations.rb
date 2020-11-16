FactoryBot.define do
  factory :location do
    uuid { SecureRandom.uuid }
    name { "Chennai" }
  end
end
