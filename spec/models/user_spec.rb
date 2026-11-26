require "rails_helper"

RSpec.describe User, type: :model do
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:menu) { create(:daily_menu, served_on:, capacity: 5, bento: create(:bento, name: "焼き鮭", price: 101)) }
  let(:other_menu) { create(:daily_menu, served_on:, bento: create(:bento, name: "煮物", bento_type: "洋食")) }
  let(:user) { create(:user) }

  around do |example|
    travel_to(Time.zone.local(2028, 2, 28, 9)) { example.run }
  end

  it "注文日ではなく提供月で利用者の保存済み合計を請求する" do
    cancelled = create(:order, user:, daily_menu: menu)
    cancelled.change_status_by_administrator(:cancelled)
    create(:order, user:, daily_menu: menu)
    received = create(:order, user:, daily_menu: other_menu, quantity: 2)
    received.change_status_by_administrator(:received)
    create(:order, daily_menu: menu)
    next_menu = create(:daily_menu, served_on: served_on.next_day)
    next_month_order = create(:order, user:, daily_menu: next_menu)
    menu.bento.update!(price: 999)

    expect(user.monthly_bill(served_on)).to eq(109 + received.total_amount)
    expect(user.monthly_bill(served_on.next_month)).to eq(next_month_order.total_amount)
    expect(user.monthly_bill(served_on.prev_month)).to eq(0)
  end
end
