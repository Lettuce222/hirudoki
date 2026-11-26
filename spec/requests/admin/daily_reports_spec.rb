require "rails_helper"

RSpec.describe Admin::DailyReportsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:served_on) { Date.new(2028, 2, 29) }

  context "利用者としてログイン済みの場合" do
    before { sign_in create(:user) }

    it "配達先を見られない" do
      get admin_daily_report_path

      expect(response).to redirect_to(new_administrator_session_path)
    end
  end

  context "管理者としてログイン済みの場合" do
    before { sign_in create(:administrator) }

    it "指定日の有効な注文を弁当別に合計し、配送先を注文別に表示する" do
      menu = create(:daily_menu, served_on:)
      order = travel_to(Time.zone.local(2028, 2, 28, 9)) do
        cancelled = create(:order, daily_menu: menu, quantity: 3, delivery_address: "取り消し済みの住所")
        cancelled.cancelled!
        create(:order, daily_menu: menu, quantity: 1)
        create(:order, daily_menu: create(:daily_menu, served_on: served_on.next_day), delivery_address: "翌日の住所")
        create(:order, daily_menu: menu, quantity: 2)
      end

      get admin_daily_report_path(served_on:)

      page = Nokogiri::HTML(response.body)
      expect(page.at_css("[aria-label='製造リスト']").text).to include(menu.bento.name, "3個")
      deliveries = page.at_css("[aria-label='配達リスト']")
      expect(deliveries.css("tbody tr").size).to eq(2)
      expect(deliveries.text).to include(order.delivery_area.name, order.delivery_address, order.user.phone, menu.bento.name, "2個")
      expect(deliveries.text).not_to include("取り消し済みの住所", "翌日の住所")
    end

    it "指定日の製造と配達が0件であることを表示する" do
      get admin_daily_report_path(served_on:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("製造する弁当はありません。", "配達する注文はありません。")
    end

    it "不正な日付の場合は入力し直せる" do
      get admin_daily_report_path(served_on: "2028-02-30")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("有効な提供日を指定してください。")
    end
  end
end
