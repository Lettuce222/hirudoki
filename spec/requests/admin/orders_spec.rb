require "rails_helper"

RSpec.describe Admin::OrdersController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:order) do
    travel_to(Time.zone.local(2028, 2, 28, 9)) do
      create(:order, daily_menu: create(:daily_menu, served_on: Date.new(2028, 2, 29)))
    end
  end

  context "未ログインの場合" do
    it "注文の詳細を表示できない" do
      get admin_order_path(order)

      expect(response).to redirect_to(new_administrator_session_path)
    end
  end

  context "利用者としてログイン済みの場合" do
    before { sign_in order.user }

    it "自分の注文でも管理者用の状態変更はできない" do
      patch admin_order_path(order), params: { order: { status: "received" } }

      expect(response).to redirect_to(new_administrator_session_path)
      expect(order.reload).to be_ordered
    end
  end

  context "管理者としてログイン済みの場合" do
    before { sign_in create(:administrator) }

    it "キャンセル済みを含む全注文を一覧と詳細で参照できる" do
      order.cancelled!

      get admin_orders_path

      expect(response.body).to include("注文 ##{order.id}", "手動", "キャンセル済")
      get admin_order_path(order)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.delivery_address, order.user.phone)
    end

    it "注文状態を保存すると評価可否と献立の残数に反映される" do
      patch admin_order_path(order), params: { order: { status: "received", total_amount: 1 } }

      expect(response).to redirect_to(admin_order_path(order))
      expect(order.reload).to be_reviewable
      expect(order.total_amount).to eq(702)

      travel_to(Time.zone.local(2028, 2, 29, 10)) do
        patch admin_order_path(order), params: { order: { status: "cancelled" } }
      end

      expect(response).to redirect_to(admin_order_path(order))
      expect(order.reload).to be_cancelled
      expect(order).not_to be_reviewable
      expect(order.daily_menu.remaining_quantity).to eq(10)
    end

    it "存在しない状態を指定すると現在の状態を保持してエラーを表示する" do
      patch admin_order_path(order), params: { order: { status: "unknown" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("注文状態")
      expect(Nokogiri::HTML(response.body).at_css("ul[role=alert]")).to be_present
      expect(order.reload).to be_ordered
    end
  end
end
