require "rails_helper"

RSpec.describe Admin::RecurringOrderGenerationsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:served_on) { Date.new(2028, 2, 29) }

  context "利用者としてログイン済みの場合" do
    before { sign_in create(:user) }

    it "管理者用の生成操作を実行できない" do
      post admin_recurring_order_generations_path, params: { recurring_order_generation: { served_on: } }

      expect(response).to redirect_to(new_administrator_session_path)
    end
  end

  context "管理者としてログイン済みの場合" do
    before { sign_in create(:administrator) }

    it "対象日の初期値を当日締切後は翌日にする" do
      travel_to(Time.zone.local(2028, 2, 28, 10)) do
        get new_admin_recurring_order_generation_path
      end

      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).at_css("input[type=date]")["value"]).to eq(served_on.iso8601)
    end

    it "受付期間外の対象日にはエラーを表示する" do
      travel_to(Time.zone.local(2028, 2, 28, 9)) do
        post admin_recurring_order_generations_path, params: { recurring_order_generation: { served_on: served_on + 14 } }
      end

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("提供日は注文受付期間内の日付を指定してください。")
    end

    it "対象日が土日なら生成もスキップも0件と表示する" do
      travel_to(Time.zone.local(2028, 2, 28, 9)) do
        post admin_recurring_order_generations_path, params: { recurring_order_generation: { served_on: served_on + 4 } }
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("生成 0件・スキップ 0件")
    end
  end
end
