FactoryBot.define do
  factory :daily_menu do
    bento
    sequence(:served_on) { |n| Date.new(2028, 2, 28) + n }
    capacity { 10 }
  end
end
