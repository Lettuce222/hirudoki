require "rails_helper"

RSpec.describe Order, type: :model do
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:menu) { create(:daily_menu, served_on:, capacity: 3, bento: create(:bento, price: 500)) }
  let(:order) { create(:order, daily_menu: menu, quantity: 2) }

  it "自分の注文分を除いて残数を計算し、注文時の単価と割引単価で金額を更新する" do
    travel_to(Time.zone.local(2028, 2, 29, 9, 59, 59)) do
      order.update!(unit_discount: 50)
      menu.bento.update!(price: 900)
      expect(menu.remaining_quantity).to eq(1)

      expect(order.change_quantity(3)).to be(true)
      expect(order.reload).to have_attributes(quantity: 3, unit_price: 500, unit_discount: 50, total_amount: 1_458)
      expect(menu.remaining_quantity).to eq(0)
    end
  end

  it "変更後に献立の上限または利用者の同日上限を超えると個数を変更できない" do
    travel_to(Time.zone.local(2028, 2, 29, 9)) do
      create(:order, daily_menu: menu)
      expect(order.change_quantity(3)).to be(false)
      expect(order.errors[:base]).to include("残数が足りません。")

      menu.update!(capacity: 10)
      other_menu = create(:daily_menu, served_on:, bento: create(:bento, bento_type: "洋食"))
      create(:order, daily_menu: other_menu, user: order.user)
      expect(order.change_quantity(3)).to be(false)
      expect(order.errors[:base]).to include("同じ提供日には合計3個まで注文できます。")
      expect(order.reload.quantity).to eq(2)
    end
  end

  it "1から3の整数以外には個数を変更できない" do
    travel_to(Time.zone.local(2028, 2, 29, 9)) do
      [ 0, 4, "1.5", "abc", nil ].each do |quantity|
        expect(order.change_quantity(quantity)).to be(false)
        expect(order.errors[:quantity]).to be_present
      end
      expect(order.reload.quantity).to eq(2)
    end
  end

  it "締切前にキャンセルすると残数と同日注文枠が戻る" do
    travel_to(Time.zone.local(2028, 2, 29, 9, 59, 59)) do
      expect(order.cancel).to be(true)
      expect(order.reload).to be_cancelled
      expect(menu.remaining_quantity).to eq(3)
      expect(create(:order, daily_menu: menu, user: order.user, quantity: 3)).to be_persisted
    end
  end

  it "提供日当日の10時以降は個数変更もキャンセルもできない" do
    existing_order = travel_to(Time.zone.local(2028, 2, 29, 9)) { order }

    [ 0, 1 ].each do |seconds_after_cutoff|
      travel_to(Time.zone.local(2028, 2, 29, 10) + seconds_after_cutoff) do
        expect(existing_order.change_quantity(1)).to be(false)
        expect(existing_order.cancel).to be(false)
      end
    end

    expect(existing_order.reload).to have_attributes(quantity: 2, status: "ordered")
  end

  it "受取済みまたはキャンセル済みの注文は変更もキャンセルもできない" do
    travel_to(Time.zone.local(2028, 2, 29, 9)) do
      %i[received cancelled].each do |status|
        order.update!(status:)
        expect(order.change_quantity(1)).to be(false)
        expect(order.cancel).to be(false)
      end
    end
  end
end
