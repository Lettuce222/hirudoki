require "rails_helper"
require_relative "../support/concurrent_writes"

RSpec.describe Order, type: :model do
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:menu) { create(:daily_menu, served_on:, capacity: 3, bento: create(:bento, price: 101)) }
  let(:user) { create(:user) }
  let(:area) { create(:delivery_area) }

  def order_for(menu_to_order = menu, **attributes)
    build(:order, daily_menu: menu_to_order, user:, delivery_area: area, **attributes)
  end

  it "09:59:59は注文でき、10:00:00とその1秒後は受付を終了する" do
    travel_to(Time.zone.local(2028, 2, 29, 9, 59, 59)) { expect(order_for.confirm).to be(true) }
    travel_to(Time.zone.local(2028, 2, 29, 10)) { expect(order_for.confirm).to be(false) }
    travel_to(Time.zone.local(2028, 2, 29, 10, 0, 1)) { expect(order_for.confirm).to be(false) }
  end

  it "日本時間の日付で過去と15日先を拒否し14日先を受け付ける" do
    travel_to(Time.utc(2028, 2, 28, 15)) do
      [ [ Date.new(2028, 2, 28), false ], [ Date.new(2028, 3, 14), true ], [ Date.new(2028, 3, 15), false ] ].each do |date, allowed|
        expect(order_for(create(:daily_menu, served_on: date)).confirm).to eq(allowed)
      end
    end
  end

  it "残数が足りない注文は確定前に検証しても理由が分かる" do
    travel_to(Time.utc(2028, 2, 28)) do
      menu.update!(capacity: 0)
      order = order_for
      expect(order).not_to be_valid
      expect(order.errors[:base]).to include("残数が足りません。")
      expect(order.unit_price).to be_nil
    end
  end

  it "配達エリアと個数が未入力なら確定時に両方のエラーが付く" do
    order = order_for(delivery_area: nil, quantity: nil)
    expect(order.confirm).to be(false)
    expect(order.errors.attribute_names).to include(:delivery_area, :quantity)
  end

  it "注文時の単価と税込合計を保存し、価格改定後も同じ金額を表示する" do
    travel_to(Time.utc(2028, 2, 28)) do
      order = order_for(quantity: 2)
      expect(order).to be_valid
      expect(order.unit_price).to be_nil
      expect(order.confirm).to be(true)
      menu.bento.update!(price: 600)
      expect(order.reload).to have_attributes(unit_price: 101, unit_discount: 0, total_amount: 218, status: "ordered")
    end
  end

  it "注文状態は英語名で操作し、データベースには対応する日本語を保存する" do
    travel_to(Time.utc(2028, 2, 28)) do
      order = order_for
      expect(order.confirm).to be(true)
      { ordered: "注文済", received: "受取済", cancelled: "キャンセル済" }.each do |key, label|
        order.update!(status: key)
        expect(order.reload.status).to eq(key.to_s)
        expect(order.status_before_type_cast).to eq(label)
      end
    end
  end

  it "割引後の小計を0円以上とし、合計に対する消費税の端数を切り捨てる" do
    expect(described_class.total_for(unit_price: 500, unit_discount: 50, quantity: 2)).to eq(972)
    expect(described_class.total_for(unit_price: 30, unit_discount: 50, quantity: 2)).to eq(0)
  end

  it "手動注文の個数は1から3の整数に限る" do
    travel_to(Time.utc(2028, 2, 28)) do
      [ 0, 4, "1.5", "abc" ].each { |quantity| expect(order_for(quantity:).confirm).to be(false) }
      expect(order_for(quantity: 3).confirm).to be(true)
    end
  end

  it "同日の別の弁当も合算し、キャンセルすると残数と利用者の枠が戻る" do
    travel_to(Time.utc(2028, 2, 28)) do
      other = create(:daily_menu, served_on:, bento: create(:bento, bento_type: "洋食"))
      first = order_for(quantity: 2)
      expect(first.confirm).to be(true)
      expect(order_for(other, quantity: 2).confirm).to be(false)
      expect(order_for(user: create(:user), quantity: 2).confirm).to be(false)
      first.cancelled!
      expect(menu.remaining_quantity).to eq(3)
      expect(order_for(other, quantity: 2).confirm).to be(true)
    end
  end

  it "販売停止やエリア無効化を送信時に再確認する" do
    travel_to(Time.utc(2028, 2, 28)) do
      area.update!(active: false)
      expect(order_for.confirm).to be(false)
      area.update!(active: true)
      menu.bento.update!(on_sale: false)
      expect(order_for.confirm).to be(false)
    end
  end

  context "注文を同時に受け付ける場合" do
    include ConcurrentWrites
    self.use_transactional_tests = false

    let(:served_on) { Date.new(2028, 2, 29) }
    let!(:menu) { create(:daily_menu, served_on:, capacity: 1) }
    let!(:other_menu) { create(:daily_menu, served_on:, bento: create(:bento, bento_type: "洋食")) }
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }
    let!(:area) { create(:delivery_area) }

    after do
      Order.where(daily_menu: [ menu, other_menu ]).delete_all
      [ menu, other_menu ].each do |record|
        record.destroy!
        record.bento.destroy!
      end
      [ user, other_user, area ].each(&:destroy!)
    end

    it "別々の利用者が最後の1個を同時注文しても1個だけ受け付ける" do
      travel_to(Time.utc(2028, 2, 28)) do
        accepted = race(-> { create(:order, user:, daily_menu: menu, delivery_area: area) }) do
          build(:order, user: other_user, daily_menu: menu, delivery_area: area).confirm
        end
        expect(accepted).to be(false)
        expect(menu.remaining_quantity).to eq(0)
      end
    end

    it "同じ利用者が別の献立を同時注文しても同日3個を超えない" do
      travel_to(Time.utc(2028, 2, 28)) do
        accepted = race(-> { create(:order, user:, daily_menu: other_menu, delivery_area: area, quantity: 3) }) do
          build(:order, user:, daily_menu: menu, delivery_area: area).confirm
        end
        expect(accepted).to be(false)
        expect(user.orders.sum(:quantity)).to eq(3)
      end
    end

    it "個数変更と別の利用者の注文が重なっても献立の提供数を超えない" do
      travel_to(Time.utc(2028, 2, 28)) do
        menu.update!(capacity: 2)
        order = create(:order, user:, daily_menu: menu, delivery_area: area)
        changed = race(-> { create(:order, user: other_user, daily_menu: menu, delivery_area: area) }) do
          Order.find(order.id).change_quantity(2)
        end

        expect(changed).to be(false)
        expect(order.reload.quantity).to eq(1)
        expect(menu.remaining_quantity).to eq(0)
      end
    end

    it "個数変更と同じ利用者の別献立の注文が重なっても同日3個を超えない" do
      travel_to(Time.utc(2028, 2, 28)) do
        menu.update!(capacity: 3)
        order = create(:order, user:, daily_menu: menu, delivery_area: area)
        changed = race(-> { create(:order, user:, daily_menu: other_menu, delivery_area: area, quantity: 2) }) do
          Order.find(order.id).change_quantity(2)
        end

        expect(changed).to be(false)
        expect(user.orders.sum(:quantity)).to eq(3)
      end
    end
  end

  context "個数変更とキャンセル" do
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

  it "受取済みで評価がまだない注文だけを評価できる" do
    travel_to(Time.utc(2028, 2, 28)) do
      order = order_for
      order.confirm
      expect(order).not_to be_reviewable

      order.received!
      expect(order).to be_reviewable

      order.create_review!(rating: 5)
      expect(order).not_to be_reviewable
    end
  end

  context "管理者が注文を管理する場合" do
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

      expect(order.change_status(:received)).to be(true)
      expect(order.reload).to be_received
      expect(menu.remaining_quantity).to eq(3)

      expect(order.change_status(:cancelled)).to be(true)
      expect(order.reload).to be_cancelled
      expect(menu.remaining_quantity).to eq(5)
    end

    it "管理者がキャンセル済み注文を戻しても残数と同日上限を超えない" do
      order = create(:order, daily_menu: menu, user:, quantity: 3)
      order.change_status(:cancelled)
      replacement = create(:order, daily_menu: menu, user:, quantity: 3)

      expect(order.change_status(:ordered)).to be(false)
      expect(order.errors[:base]).to include("残数が足りません。", "同じ提供日には合計3個まで注文できます。")
      expect(Order.find(order.id)).to be_cancelled

      replacement.change_status(:cancelled)
      expect(order.change_status(:ordered)).to be(true)
      expect(order.reload).to be_ordered
    end

    it "管理者が未知の状態を指定しても現在の状態が保たれる" do
      order = create(:order, daily_menu: menu)

      expect(order.change_status("無効な状態")).to be(false)
      expect(order.errors[:status]).to be_present
      expect(order.reload).to be_ordered
    end

    it "指定日の製造数を弁当ごとに合計し、配達にはキャンセル以外の各注文を載せる" do
      first = create(:order, daily_menu: menu, quantity: 2)
      second = create(:order, daily_menu: menu, quantity: 1)
      second.change_status(:received)
      cancelled = create(:order, daily_menu: menu, quantity: 1)
      cancelled.change_status(:cancelled)
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
  end
end
