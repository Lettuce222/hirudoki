FactoryBot.define do
  factory :order do
    user
    daily_menu
    delivery_area
    delivery_address { "駅前一丁目3番地" }
    quantity { 1 }
  end
end
