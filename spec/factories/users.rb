FactoryBot.define do
  factory :user do
    name { "花子" }
    sequence(:email) { |n| "user#{n}@example.test" }
    phone { "09012345678" }
    password { "sample-password" }
    password_confirmation { password }
  end
end
