require "rails_helper"

RSpec.describe "管理画面のアクセス境界", type: :request do
  let(:user) { User.create!(email: "someone@example.test", name: "利用者", phone: "09000000000", password: "user-password", password_confirmation: "user-password") }
  let(:administrator) { Administrator.create!(email: user.email, name: "管理担当", password: "admin-password") }

  it "管理用URLはログインが必要で、管理者登録ルートはない" do
    get "/admin"
    expect(response).to redirect_to(new_administrator_session_path)
    get "/admin/sign_up"
    expect(response).to have_http_status(:not_found)
    post "/admin"
    expect(response).to have_http_status(:not_found)
  end

  it "利用者権限では管理画面が開けず、同じメールの利用者パスワードで管理者ログインできない" do
    post user_session_path, params: { user: { email: user.email, password: "user-password" } }
    get admin_root_path
    expect(response).to redirect_to(new_administrator_session_path)
    post administrator_session_path, params: { administrator: { email: administrator.email, password: "user-password" } }
    expect(response).to have_http_status(:unprocessable_content)
    get admin_root_path
    expect(response).to redirect_to(new_administrator_session_path)
  end

  it "管理者のログインだけでは利用者のマイページが開けない" do
    post administrator_session_path, params: { administrator: { email: administrator.email, password: "admin-password" } }
    get profile_path
    expect(response).to redirect_to(root_path)
  end

  it "利用者のマイページは別の利用者のIDを指定しても本人だけを表示する" do
    other = User.create!(email: "other@example.test", name: "別の利用者", phone: "08011111111", password: "other-password", password_confirmation: "other-password")
    post user_session_path, params: { user: { email: user.email, password: "user-password" } }
    get profile_path, params: { id: other.id }
    expect(response.body).to include(user.email)
    expect(response.body).not_to include(other.email)
  end

  it "管理者からのログアウトは同じブラウザの利用者セッションを保つ" do
    post user_session_path, params: { user: { email: user.email, password: "user-password" } }
    post administrator_session_path, params: { administrator: { email: administrator.email, password: "admin-password" } }
    delete destroy_administrator_session_path
    expect(response).to redirect_to(new_administrator_session_path)
    get profile_path
    expect(response.body).to include(user.email)
    get admin_root_path
    expect(response).to redirect_to(new_administrator_session_path)
  end
end
