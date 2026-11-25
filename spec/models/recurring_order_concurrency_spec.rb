require "rails_helper"
require_relative "../support/concurrent_writes"

RSpec.describe "定期注文の同時生成", type: :model do
  include ConcurrentWrites
  self.use_transactional_tests = false

  let(:served_on) { Date.new(2028, 2, 29) }
  let!(:menu) { create(:daily_menu, served_on:, bento: create(:bento, bento_type: "和食")) }
  let!(:other_menu) { create(:daily_menu, served_on:, bento: create(:bento, bento_type: "洋食")) }
  let!(:setting) { create(:recurring_order_setting, quantity: 2) }

  after do
    Order.where(user: setting.user).delete_all
    setting.destroy!
    setting.user.destroy!
    setting.delivery_area.destroy!
    [ menu, other_menu ].each do |record|
      record.destroy!
      record.bento.destroy!
    end
  end

  it "別々の接続から同じ日に生成しても同じ設定の注文は1件だけになる" do
    travel_to(Time.utc(2028, 2, 28)) do
      first = RecurringOrderGeneration.new(served_on:)
      second = RecurringOrderGeneration.new(served_on:)
      race(-> { first.generate }) { second.generate }

      expect(setting.orders.count).to eq(1)
      expect(first.orders.size).to eq(1)
      expect(second.skips.sole.reason).to eq("この対象日は生成済みです。")
    end
  end

  it "手動注文と生成が競合しても同じ利用者の同日上限を超えない" do
    travel_to(Time.utc(2028, 2, 28)) do
      generation = RecurringOrderGeneration.new(served_on:)
      race(-> { create(:order, daily_menu: other_menu, user: setting.user, delivery_area: setting.delivery_area, quantity: 2) }) { generation.generate }

      expect(setting.user.orders.sum(:quantity)).to eq(2)
      expect(generation.skips.sole.reason).to eq("同じ提供日には合計3個まで注文できます。")
    end
  end
end
