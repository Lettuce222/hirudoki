module OrdersHelper
  def order_quantity_options(menu, remaining)
    (1..[ Order::DAILY_LIMIT, remaining ].min).map do |quantity|
      total = Order.total_for(unit_price: menu.bento.price, quantity:)
      [ "#{quantity}個（税込#{number_with_delimiter(total)}円）", quantity ]
    end
  end
end
