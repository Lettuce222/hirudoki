require "rails_helper"

RSpec.describe "マイページ", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { User.create!(name: "花子", email: "hana@example.org", phone: "09012345678", password: "sample-password", password_confirmation: "sample-password") }

  it "ログインした利用者のマイページをキャッシュに保存させない" do
    sign_in user
    get profile_path

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control").split(/,\s*/)).to include("no-store")
  end
end
