FactoryBot.define do
  factory :user, aliases: [:created_by] do
    id { SecureRandom.uuid }
    sequence(:name) { |n| "User-#{n}" }
    password { "password" }
    email { "name@domain.com" }
  end
end
