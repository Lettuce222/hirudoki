FactoryBot.define do
  factory :order do
    user
    daily_menu
    delivery_area
    delivery_address { "駅前一丁目3番地" }
    quantity { 1 }

    to_create do |order|
      raise ActiveRecord::RecordInvalid, order unless order.confirm
    end
  end
end
