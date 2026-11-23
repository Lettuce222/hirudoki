require "rails_helper"

RSpec.describe "利用者のログイン", type: :request do
  it "未登録のメールアドレスもパスワード誤りと同じ認証失敗として扱う" do
    post user_session_path, params: { user: { email: "unknown@example.test", password: "sample-password" } }

    expect(request.env.fetch("warden.options").fetch(:message)).to eq(:invalid)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("メールアドレスまたはパスワードが正しくありません。")
  end
end
