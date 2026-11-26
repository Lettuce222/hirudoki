require "rails_helper"

RSpec.describe RecurringOrderSettingsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:area) { create(:delivery_area) }
  let(:settings) do
    { weekday: 2, bento_type: "和食", quantity: 2, delivery_area_id: area.id,
      delivery_address: "駅前一丁目3番地", active: true }
  end

  context "未ログインの場合" do
    it "定期注文設定の一覧を表示できない" do
      get recurring_order_settings_path

      expect(response).to redirect_to(root_path)
    end

    it "定期注文設定を登録できない" do
      expect do
        post recurring_order_settings_path, params: { recurring_order_setting: settings }
      end.not_to change(RecurringOrderSetting, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  context "利用者としてログイン済みの場合" do
    before { sign_in user }

    it "リクエストに別の利用者を指定しても自分の定期注文設定を登録する" do
      post recurring_order_settings_path, params: { recurring_order_setting: settings.merge(user_id: create(:user).id) }

      expect(response).to redirect_to(recurring_order_settings_path)
      expect(user.recurring_order_settings.sole).to have_attributes(settings)
    end

    it "他の利用者の定期注文設定の編集画面を表示できない" do
      get edit_recurring_order_setting_path(create(:recurring_order_setting))

      expect(response).to have_http_status(:not_found)
    end

    it "他の利用者の定期注文設定を変更できない" do
      setting = create(:recurring_order_setting)

      patch recurring_order_setting_path(setting), params: { recurring_order_setting: { active: false } }

      expect(response).to have_http_status(:not_found)
      expect(setting.reload).to be_active
    end

    it "同じ曜日の定期注文設定を重複して登録できない" do
      create(:recurring_order_setting, user:, weekday: 2)

      post recurring_order_settings_path, params: { recurring_order_setting: settings }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("曜日は登録済みです")
    end

    it "週末の設定や受付終了した配達エリアを新規登録できない" do
      area.update!(active: false)

      post recurring_order_settings_path, params: { recurring_order_setting: settings.merge(weekday: 6) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("曜日", "配達エリアは受付を終了しました。")
      expect(user.recurring_order_settings.reload).to be_empty
    end

    it "受付終了した配達エリアを保持したまま自分の定期注文設定を無効化できる" do
      setting = create(:recurring_order_setting, user:, delivery_area: area)
      area.update!(active: false)

      get edit_recurring_order_setting_path(setting)
      expect(response.body).to include("#{area.name}（受付終了）")

      patch recurring_order_setting_path(setting), params: { recurring_order_setting: { active: false } }

      expect(response).to redirect_to(recurring_order_settings_path)
      expect(setting.reload).to have_attributes(active: false, delivery_area: area)
    end
  end
end
