FactoryBot.define do
  factory :daily_menu do
    bento
    sequence(:served_on) { |n| Date.current + n }
    capacity { 10 }
  end
end
