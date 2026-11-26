require "rails_helper"

RSpec.describe Admin::SessionsController, type: :request do
  include Devise::Test::IntegrationHelpers

  it "同じメールアドレスでも利用者のパスワードで管理者としてログインできない" do
    user = create(:user, password: "user-password")
    administrator = create(:administrator, email: user.email, password: "admin-password")

    post administrator_session_path, params: { administrator: { email: administrator.email, password: user.password } }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "管理者からログアウトしても利用者セッションは保たれる" do
    user = create(:user)
    sign_in user
    sign_in create(:administrator)

    delete destroy_administrator_session_path

    expect(response).to redirect_to(new_administrator_session_path)
    expect(request.env.fetch("warden").user(:user)).to eq(user)
    expect(request.env.fetch("warden").user(:administrator)).to be_nil
  end
end
