require "rails_helper"

RSpec.describe Admin::DeliveryAreasController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:area_attributes) { { name: "本町", postal_code: "0012345" } }

  context "未ログインの場合" do
    it "配達エリアを登録できない" do
      expect { post admin_delivery_areas_path, params: { delivery_area: area_attributes } }.not_to change(DeliveryArea, :count)
      expect(response).to redirect_to(new_administrator_session_path)
    end
  end

  context "管理者としてログイン済みの場合" do
    before { sign_in create(:administrator) }

    it "郵便番号の入力エラーを修正して保存し、未参照エリアを削除できる" do
      post admin_delivery_areas_path, params: { delivery_area: area_attributes.merge(postal_code: "abc") }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("郵便番号")
      post admin_delivery_areas_path, params: { delivery_area: area_attributes }
      area = DeliveryArea.find_by!(postal_code: "0012345")
      expect { delete admin_delivery_area_path(area) }.to change(DeliveryArea, :count).by(-1)
    end

    it "キャンセル済み注文が参照する配達エリアは削除できない" do
      area = create(:delivery_area)
      menu = create(:daily_menu, served_on: Date.new(2028, 2, 29))
      travel_to(Time.utc(2028, 2, 28)) do
        create(:order, daily_menu: menu, delivery_area: area).cancelled!
      end

      expect { delete admin_delivery_area_path(area) }.not_to change(DeliveryArea, :count)
      expect(response).to redirect_to(admin_delivery_areas_path)
    end
  end
end
