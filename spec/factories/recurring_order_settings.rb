FactoryBot.define do
  factory :recurring_order_setting do
    user
    delivery_area
    weekday { 2 }
    bento_type { "和食" }
    quantity { 1 }
    delivery_address { "駅前一丁目3番地" }
    active { true }
  end
end
