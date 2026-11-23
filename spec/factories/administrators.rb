FactoryBot.define do
  factory :administrator do
    name { "管理担当" }
    sequence(:email) { |n| "admin#{n}@example.test" }
    password { "admin-password" }
    password_confirmation { password }
  end
end
