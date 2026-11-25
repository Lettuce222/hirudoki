require "rails_helper"
require_relative "../support/concurrent_writes"

RSpec.describe "手動注文の同時受付", type: :model do
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
end
