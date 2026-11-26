require "rails_helper"

RSpec.describe OrderCancellationsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:order) do
    travel_to(Time.zone.local(2028, 2, 29, 9)) do
      create(:order, daily_menu: create(:daily_menu, served_on: Date.new(2028, 2, 29)))
    end
  end

  context "未ログインの場合" do
    it "注文をキャンセルできない" do
      post order_cancellation_path(order)
      expect(response).to redirect_to(root_path)
      expect(order.reload).to be_ordered
    end
  end

  context "ログイン済みの場合" do
    before { sign_in order.user }

    it "締切前にキャンセルすると注文詳細に戻り、献立の残数が戻る" do
      travel_to(Time.zone.local(2028, 2, 29, 9, 59, 59)) do
        expect { post order_cancellation_path(order) }.to change { order.daily_menu.remaining_quantity }.by(1)
        expect(response).to redirect_to(order_path(order))
        expect(order.reload).to be_cancelled
      end
    end

    it "締切に達した注文はキャンセルできない" do
      travel_to(Time.zone.local(2028, 2, 29, 10)) do
        post order_cancellation_path(order)
        expect(response).to redirect_to(order_path(order))
        expect(flash[:alert]).to include("この注文は変更・キャンセルできません。")
        expect(order.reload).to be_ordered
      end
    end

    it "別の利用者の注文をキャンセルできない" do
      other_order = travel_to(Time.zone.local(2028, 2, 29, 9)) { create(:order, daily_menu: order.daily_menu) }

      post order_cancellation_path(other_order)
      expect(response).to have_http_status(:not_found)
      expect(other_order.reload).to be_ordered
    end
  end
end
