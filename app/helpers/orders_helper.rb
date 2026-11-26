module OrdersHelper
  def order_quantity_options(unit_price:, remaining:, unit_discount: 0)
    (1..[ Order::DAILY_LIMIT, remaining ].min).map do |quantity|
      total = Order.total_for(unit_price:, quantity:, unit_discount:)
      [ "#{quantity}個（税込#{number_with_delimiter(total)}円）", quantity ]
    end
  end
end
