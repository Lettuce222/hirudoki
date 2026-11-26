require "rails_helper"

RSpec.describe "動作確認用のシード" do
  let(:first_day) { Date.new(2028, 2, 28) }
  let(:days) { first_day..first_day + 14 }

  around do |example|
    travel_to(first_day.in_time_zone) { example.run }
  end

  before do
    stub_const("ENV", ENV.to_h.except("SEED_ADMIN_EMAIL", "SEED_ADMIN_PASSWORD", "SEED_USER_EMAIL", "SEED_USER_PASSWORD"))
  end

  it "確認期間の各日に販売中の献立を4タイプ用意する" do
    load Rails.root.join("db/seeds/demo.rb")

    offered_types = DailyMenu.on_sale.pluck(:served_on, "bentos.bento_type").group_by(&:first)
    expect(offered_types.keys.sort).to eq(days.to_a)
    expect(offered_types.values.map { |rows| rows.map(&:last).sort }.uniq).to eq([ Bento::BENTO_TYPES.sort ])
    expect(DailyMenu.distinct.count(:bento_id)).to eq(8)
    expect(DeliveryArea.active.count).to eq(3)
  end

  it "開発用のアカウントと平日の定期注文設定を一度ずつ作る" do
    2.times { load Rails.root.join("db/seeds/demo.rb") }

    administrator = Administrator.find_by!(email: "demo-admin@example.test")
    user = User.find_by!(email: "demo-user@example.test")
    expect(administrator.valid_password?("hirudoki-local-admin")).to be(true)
    expect(user.valid_password?("hirudoki-local-user")).to be(true)
    expect(user.recurring_order_settings.active.asc_by_weekday.pluck(:weekday)).to eq([ 1, 2, 3, 4, 5 ])
    expect(DailyMenu.count).to eq(days.count * Bento::BENTO_TYPES.size)
    expect(Bento.find_by!(name: "焼き鮭のり弁当").image).to be_attached
  end

  context "既存のアカウントやデータと重なる場合" do
    let!(:administrator) { create(:administrator, email: "demo-admin@example.test") }
    let!(:existing_area) { create(:delivery_area, postal_code: "1000005", active: false) }
    let!(:existing_menu) do
      create(:daily_menu, served_on: first_day, bento: create(:bento, on_sale: false), capacity: 3)
    end

    it "既存データを保ち、空いている日付とタイプを補う" do
      expect { load Rails.root.join("db/seeds/demo.rb") }.to output(/#{first_day}: 和食/).to_stderr

      expect(administrator.reload.valid_password?(administrator.password)).to be(true)
      expect(existing_area.reload).not_to be_active
      expect(existing_menu.reload.capacity).to eq(3)
      expect(existing_menu.bento).not_to be_on_sale
      expect(DailyMenu.where(served_on: first_day).count).to eq(4)
      expect(RecurringOrderSetting.pluck(:delivery_area_id).uniq).not_to include(existing_area.id)
    end
  end
end
