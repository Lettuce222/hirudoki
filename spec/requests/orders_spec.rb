require "rails_helper"

RSpec.describe OrdersController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let!(:area) { create(:delivery_area) }
  let(:menu) { create(:daily_menu, served_on: Date.new(2028, 2, 29)) }
  let(:attributes) { { quantity: 1, delivery_area_id: area.id, delivery_address: "駅前一丁目" } }
  let(:order) { travel_to(Time.zone.local(2028, 2, 29, 9)) { create(:order, daily_menu: menu, user:) } }
  let(:other_order) { travel_to(Time.zone.local(2028, 2, 29, 9)) { create(:order, daily_menu: menu) } }

  context "利用者としてログインしていない場合" do
    it "未ログインと管理者専用のセッションからは注文できない" do
      post daily_menu_orders_path(menu), params: { order: attributes }
      expect(response).to redirect_to(root_path)
      sign_in create(:administrator)
      post daily_menu_orders_path(menu), params: { order: attributes }
      expect(response).to redirect_to(root_path)
      expect(Order.count).to eq(0)
    end

    it "注文詳細を開けない" do
      get order_path(order)
      expect(response).to redirect_to(root_path)
    end
  end

  context "利用者としてログイン済みの場合" do
    before { sign_in user }

    it "利用者と価格はサーバーが決定する" do
      other = create(:user)
      travel_to(Time.utc(2028, 2, 28)) do
        post daily_menu_orders_path(menu), params: { order: attributes.merge(user_id: other.id, total_amount: 1) }
        expect(response).to redirect_to(profile_path)
        expect(user.orders.sole.total_amount).to eq(702)
      end
    end

    it "注文画面を開いた後に締切を迎えたら注文は保存されない" do
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
      travel_to(Time.utc(2028, 2, 28)) do
        create(:order, user:, daily_menu: menu, delivery_area: area)
        latest = create(:order, user:, daily_menu: menu, delivery_address: "駅前二丁目")
        latest.cancelled!
        latest.delivery_area.update!(active: false)
        get new_daily_menu_order_path(menu)
        expect(response.body).to include("駅前二丁目")
        expect(response.body).not_to include(%(value="#{latest.delivery_area_id}">#{latest.delivery_area.name}))
      end
    end

    it "注文詳細の配達先を表示し、キャッシュさせない" do
      get order_path(order)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.delivery_address)
      expect(response.headers.fetch("Cache-Control").split(/,\s*/)).to include("no-store")
    end

    it "別の利用者の注文を閲覧できない" do
      get order_path(other_order)

      expect(response).to have_http_status(:not_found)
    end

    it "別の利用者の注文を変更できない" do
      patch order_path(other_order), params: { order: { quantity: 2 } }
      expect(response).to have_http_status(:not_found)
      expect(other_order.reload.quantity).to eq(1)
    end

    it "締切前は個数だけを変更し、保存済みの単価で再計算する" do
      started_order = order
      menu.bento.update!(price: 750)

      travel_to(Time.zone.local(2028, 2, 29, 9, 59, 59)) do
        patch order_path(started_order), params: { order: { quantity: 2, delivery_address: "別の住所", unit_price: 750 } }

        expect(response).to redirect_to(order_path(started_order))
        expect(started_order.reload).to have_attributes(quantity: 2, total_amount: 1_404, delivery_address: "駅前一丁目3番地")
      end
    end

    it "入力エラーがあると個数変更画面にエラーを表示する" do
      started_order = order

      travel_to(Time.zone.local(2028, 2, 29, 9)) do
        patch order_path(started_order), params: { order: { quantity: 4 } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("個数は1〜3個で指定してください")
        expect(started_order.reload.quantity).to eq(1)
      end
    end

    it "締切を迎えると個数を変更できない" do
      started_order = order

      travel_to(Time.zone.local(2028, 2, 29, 10)) do
        patch order_path(started_order), params: { order: { quantity: 2 } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("この注文は変更・キャンセルできません。")
        expect(started_order.reload.quantity).to eq(1)
      end
    end
  end
end
