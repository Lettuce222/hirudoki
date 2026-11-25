require "rails_helper"

RSpec.describe RecurringOrderGeneration do
  let(:served_on) { Date.new(2028, 2, 29) }

  it "対象日は当日から14日先で、当日10時に受付を終了する" do
    travel_to(Time.utc(2028, 2, 29, 0, 59, 59)) do
      expect(described_class.new(served_on:).generate).to be(true)
      expect(described_class.new(served_on: served_on + 14).generate).to be(true)
      expect(described_class.new(served_on: served_on + 15).generate).to be(false)
      expect(described_class.new(served_on: served_on - 1).generate).to be(false)
    end
    travel_to(Time.utc(2028, 2, 29, 1)) do
      expect(described_class.new(served_on:).generate).to be(false)
    end
  end

  it "対象日の曜日が土日なら注文を生成しない" do
    travel_to(Time.utc(2028, 2, 28)) do
      expect { described_class.new(served_on: served_on + 4).generate }.not_to change(Order, :count)
      expect { described_class.new(served_on: served_on + 5).generate }.not_to change(Order, :count)
    end
  end

  it "有効な同曜日の設定から上限を超えて生成し、注文時の単価と割引を保持する" do
    travel_to(Time.utc(2028, 2, 28)) do
      bento = create(:bento, bento_type: "和食", price: 500)
      menu = create(:daily_menu, served_on:, bento:, capacity: 1)
      create(:order, daily_menu: menu)
      setting = create(:recurring_order_setting, quantity: 2)
      create(:recurring_order_setting, active: false)
      create(:recurring_order_setting, weekday: 3)

      generation = described_class.new(served_on:)
      expect(generation.generate).to be(true)
      generated = generation.orders.sole
      expect(generated).to have_attributes(user: setting.user, daily_menu: menu, recurring_order_setting: setting,
        recurring_served_on: served_on, unit_price: 500, unit_discount: 50, total_amount: 972, quantity: 2,
        delivery_area: setting.delivery_area, delivery_address: setting.delivery_address)
      expect(generation.skips).to be_empty
      expect(menu.remaining_quantity).to eq(0)
      bento.update!(price: 700)
      setting.update!(quantity: 1, delivery_address: "別の住所", active: false)
      expect(generated.reload).to have_attributes(unit_price: 500, quantity: 2, total_amount: 972,
        delivery_address: "駅前一丁目3番地")
    end
  end

  it "販売中の献立がない設定、配達エリアが無効な設定、同日上限を超える設定を理由付きでスキップする" do
    travel_to(Time.utc(2028, 2, 28)) do
      create(:daily_menu, served_on:, bento: create(:bento, bento_type: "和食"))
      other_menu = create(:daily_menu, served_on:, bento: create(:bento, bento_type: "ヘルシー"))
      create(:daily_menu, served_on:, bento: create(:bento, bento_type: "洋食", on_sale: false))
      sold_out_type = create(:recurring_order_setting, bento_type: "洋食")
      area = create(:delivery_area)
      inactive_area = create(:recurring_order_setting, delivery_area: area)
      area.update!(active: false)
      excessive_quantity = create(:recurring_order_setting, quantity: 2)
      create(:order, user: excessive_quantity.user, daily_menu: other_menu, quantity: 2)

      generation = described_class.new(served_on:)
      expect(generation.generate).to be(true)
      expect(generation.orders).to be_empty
      expect(generation.skips.map { |skip| [ skip.user_name, skip.reason ] }).to match_array([
        [ sold_out_type.user.name, "販売中の献立がありません。" ],
        [ inactive_area.user.name, "この配達エリアは受付を終了しました。" ],
        [ excessive_quantity.user.name, "同じ提供日には合計3個まで注文できます。" ]
      ])
    end
  end

  it "キャンセル後に設定のタイプが変わっても同じ日の注文を生成しない" do
    travel_to(Time.utc(2028, 2, 28)) do
      menu = create(:daily_menu, served_on:, bento: create(:bento, bento_type: "和食"))
      other_menu = create(:daily_menu, served_on:, bento: create(:bento, bento_type: "洋食"))
      setting = create(:recurring_order_setting)
      generation = described_class.new(served_on:)
      generation.generate
      order = generation.orders.sole
      order.cancelled!
      setting.update!(bento_type: "洋食")

      expect { generation.generate }.not_to change(Order, :count)
      expect(generation.skips.sole.reason).to eq("この対象日は生成済みです。")
      expect(menu.update(served_on: served_on + 1)).to be(false)
      expect do
        Order.insert_all!([ order.attributes.except("id").merge("daily_menu_id" => other_menu.id) ])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
