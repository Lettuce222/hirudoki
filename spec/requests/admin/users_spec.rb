require "rails_helper"

RSpec.describe Admin::UsersController, type: :request do
  include Devise::Test::IntegrationHelpers

  context "利用者としてログイン済みの場合" do
    it "管理用の利用者一覧と請求額を見られない" do
      user = create(:user)
      sign_in user

      get admin_users_path

      expect(response).to redirect_to(new_administrator_session_path)
      get admin_user_path(user)

      expect(response).to redirect_to(new_administrator_session_path)
    end
  end

  context "管理者としてログイン済みの場合" do
    before { sign_in create(:administrator) }

    it "一覧から登録済み利用者の詳細に進める" do
      user = create(:user)

      get admin_users_path

      document = Nokogiri::HTML(response.body)
      expect(document.at_css("a[href='#{admin_user_path(user)}']").text).to eq(user.name)
      get admin_user_path(user)

      expect(response.body).to include(user.name, user.email, user.phone)
    end

    it "選択した月の請求額と注文がない月の0円を表示する" do
      user = create(:user)
      travel_to(Time.zone.local(2028, 2, 28, 9)) do
        menu = create(:daily_menu, served_on: Date.new(2028, 3, 1))
        create(:order, daily_menu: menu, user:, quantity: 2)
      end

      get admin_user_path(user, month: "2028-03")

      expect(response.body).to include("2028年03月の請求額", "税込1,404円")
      get admin_user_path(user, month: "2028-02")

      expect(response.body).to include("2028年02月の請求額", "税込0円")
    end

    it "請求月の代わりにオブジェクトが送られた場合は不正なリクエストとして扱う" do
      get admin_user_path(create(:user), month: { value: "2028-02" })

      expect(response).to have_http_status(:bad_request)
    end

    it "不正な月の場合は入力し直せる" do
      get admin_user_path(create(:user), month: "2028-13")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("有効な請求月を指定してください。")
    end
  end
end
