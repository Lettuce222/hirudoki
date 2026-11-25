require "rails_helper"

RSpec.describe Order, type: :model do
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:menu) { create(:daily_menu, served_on:, capacity: 3, bento: create(:bento, price: 101)) }
  let(:user) { create(:user) }
  let(:area) { create(:delivery_area) }

  def order_for(menu_to_order = menu, **attributes)
    build(:order, daily_menu: menu_to_order, user:, delivery_area: area, **attributes)
  end

  it "09:59:59は注文でき、10:00:00とその1秒後は受付を終了する" do
    travel_to(Time.zone.local(2028, 2, 29, 9, 59, 59)) { expect(order_for.save).to be(true) }
    travel_to(Time.zone.local(2028, 2, 29, 10)) { expect(order_for.save).to be(false) }
    travel_to(Time.zone.local(2028, 2, 29, 10, 0, 1)) { expect(order_for.save).to be(false) }
  end

  it "日本時間の日付で過去と15日先を拒否し14日先を受け付ける" do
    travel_to(Time.utc(2028, 2, 28, 15)) do
      [ [ Date.new(2028, 2, 28), false ], [ Date.new(2028, 3, 14), true ], [ Date.new(2028, 3, 15), false ] ].each do |date, allowed|
        expect(order_for(create(:daily_menu, served_on: date)).save).to eq(allowed)
      end
    end
  end

  it "注文時の単価と税込合計を保存し、価格改定後も同じ金額を表示する" do
    travel_to(Time.utc(2028, 2, 28)) do
      order = order_for(quantity: 2)
      order.save!
      menu.bento.update!(price: 600)
      expect(order.reload).to have_attributes(unit_price: 101, unit_discount: 0, total_amount: 218, status: "注文済")
    end
  end

  it "割引後の小計を0円以上とし、合計に対する消費税の端数を切り捨てる" do
    expect(described_class.total_for(unit_price: 500, unit_discount: 50, quantity: 2)).to eq(972)
    expect(described_class.total_for(unit_price: 30, unit_discount: 50, quantity: 2)).to eq(0)
  end

  it "手動注文の個数は1から3の整数に限る" do
    travel_to(Time.utc(2028, 2, 28)) do
      [ 0, 4, "1.5", "abc" ].each { |quantity| expect(order_for(quantity:).save).to be(false) }
      expect(order_for(quantity: 3).save).to be(true)
    end
  end

  it "同日の別の弁当も合算し、キャンセルすると残数と利用者の枠が戻る" do
    travel_to(Time.utc(2028, 2, 28)) do
      other = create(:daily_menu, served_on:, bento: create(:bento, bento_type: "洋食"))
      first = order_for(quantity: 2)
      first.save!
      expect(order_for(other, quantity: 2).save).to be(false)
      expect(order_for(user: create(:user), quantity: 2).save).to be(false)
      first.update!(status: "キャンセル済")
      expect(menu.remaining_quantity).to eq(3)
      expect(order_for(other, quantity: 2).save).to be(true)
    end
  end

  it "販売停止やエリア無効化を送信時に再確認する" do
    travel_to(Time.utc(2028, 2, 28)) do
      area.update!(active: false)
      expect(order_for.save).to be(false)
      area.update!(active: true)
      menu.bento.update!(on_sale: false)
      expect(order_for.save).to be(false)
    end
  end
end
