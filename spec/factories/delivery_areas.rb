FactoryBot.define do
  factory :delivery_area do
    name { "配達エリア" }
    sequence(:postal_code) { |n| format("%07d", n) }
  end
end
