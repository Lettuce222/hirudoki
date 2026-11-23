FactoryBot.define do
  factory :bento do
    name { "日替わり弁当" }
    bento_type { "和食" }
    price { 650 }
    display_order { 1 }
  end
end
