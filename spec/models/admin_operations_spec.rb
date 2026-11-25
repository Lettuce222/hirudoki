require "rails_helper"

RSpec.describe "管理業務の注文", type: :model do
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:menu) { create(:daily_menu, served_on:, capacity: 5, bento: create(:bento, name: "焼き鮭", price: 101)) }
  let(:other_menu) { create(:daily_menu, served_on:, bento: create(:bento, name: "煮物", bento_type: "洋食")) }
  let(:user) { create(:user) }

  around do |example|
    travel_to(Time.zone.local(2028, 2, 28, 9)) { example.run }
  end

  it "管理者は締切後でも注文を受取済み・キャンセル済みに変更できる" do
    order = create(:order, daily_menu: menu, user:, quantity: 2)
    travel(1.day + 1.hour)

    expect(order.change_status_by_administrator(:received)).to be(true)
    expect(order.reload).to be_received
    expect(menu.remaining_quantity).to eq(3)
    expect(user.monthly_bill(served_on)).to eq(218)

    expect(order.change_status_by_administrator(:cancelled)).to be(true)
    expect(order.reload).to be_cancelled
    expect(menu.remaining_quantity).to eq(5)
    expect(user.monthly_bill(served_on)).to eq(0)
  end

  it "管理者がキャンセル済み注文を戻しても残数と同日上限を超えない" do
    order = create(:order, daily_menu: menu, user:, quantity: 3)
    order.change_status_by_administrator(:cancelled)
    replacement = create(:order, daily_menu: menu, user:, quantity: 3)

    expect(order.change_status_by_administrator(:ordered)).to be(false)
    expect(order.errors[:base]).to include("残数が足りません。", "同じ提供日には合計3個まで注文できます。")
    expect(Order.find(order.id)).to be_cancelled

    replacement.change_status_by_administrator(:cancelled)
    expect(order.change_status_by_administrator(:ordered)).to be(true)
    expect(order.reload).to be_ordered
  end

  it "管理者が未知の状態を指定しても現在の状態が保たれる" do
    order = create(:order, daily_menu: menu)

    expect(order.change_status_by_administrator("無効な状態")).to be(false)
    expect(order.errors[:status]).to be_present
    expect(order.reload).to be_ordered
  end

  it "指定日の製造数を弁当ごとに合計し、配達にはキャンセル以外の各注文を載せる" do
    first = create(:order, daily_menu: menu, quantity: 2)
    second = create(:order, daily_menu: menu, quantity: 1)
    second.change_status_by_administrator(:received)
    cancelled = create(:order, daily_menu: menu, quantity: 1)
    cancelled.change_status_by_administrator(:cancelled)
    other = create(:order, daily_menu: other_menu, quantity: 2)
    tomorrow = served_on.next_day
    create(:order, daily_menu: create(:daily_menu, served_on: tomorrow))

    expect(Order.production_quantities(served_on)).to eq(
      { [ menu.bento.id, "焼き鮭" ] => 3, [ other_menu.bento.id, "煮物" ] => 2 }
    )
    expect(Order.for_delivery(served_on)).to contain_exactly(first, second, other)
    expect(Order.production_quantities(served_on.prev_day)).to be_empty
    expect(Order.for_delivery(served_on.prev_day)).to be_empty
  end

  it "注文日ではなく提供月で利用者の保存済み合計を請求する" do
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
