require "rails_helper"

RSpec.describe "手動注文の受付", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let!(:area) { create(:delivery_area) }
  let(:menu) { create(:daily_menu, served_on: Date.new(2028, 2, 29)) }
  let(:attributes) { { quantity: 1, delivery_area_id: area.id, delivery_address: "駅前一丁目" } }

  it "未ログインと管理者専用のセッションからは注文できない" do
    post daily_menu_orders_path(menu), params: { order: attributes }
    expect(response).to redirect_to(root_path)
    sign_in create(:administrator)
    post daily_menu_orders_path(menu), params: { order: attributes }
    expect(response).to redirect_to(root_path)
    expect(Order.count).to eq(0)
  end

  it "利用者と価格はサーバーが決定し、別の利用者のマイページには表示されない" do
    other = create(:user)
    sign_in user
    travel_to(Time.utc(2028, 2, 28)) do
      post daily_menu_orders_path(menu), params: { order: attributes.merge(user_id: other.id, total_amount: 1) }
      expect(response).to redirect_to(profile_path)
      expect(user.orders.sole.total_amount).to eq(702)
    end
    sign_in other
    get profile_path
    expect(response.body).not_to include("駅前一丁目")
  end

  it "注文画面を開いた後に締切を迎えたら注文は保存されない" do
    sign_in user
    travel_to(Time.utc(2028, 2, 29, 0, 59, 59)) do
      get new_daily_menu_order_path(menu)
      expect(response.body).to include("注文確定")
    end
    travel_to(Time.utc(2028, 2, 29, 1)) do
      expect { post daily_menu_orders_path(menu), params: { order: attributes } }.not_to change(Order, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("注文受付期間外")
    end
  end

  it "最近キャンセルした注文の住所も引き継ぎ、無効化されたエリアは選び直す" do
    sign_in user
    travel_to(Time.utc(2028, 2, 28)) do
      create(:order, user:, daily_menu: menu, delivery_area: area)
      latest = create(:order, user:, daily_menu: menu, delivery_address: "駅前二丁目")
      latest.update!(status: "キャンセル済")
      latest.delivery_area.update!(active: false)
      get new_daily_menu_order_path(menu)
      expect(response.body).to include("駅前二丁目")
      expect(response.body).not_to include(%(value="#{latest.delivery_area_id}">#{latest.delivery_area.name}))
    end
  end
end
