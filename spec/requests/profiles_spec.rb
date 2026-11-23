require "rails_helper"

RSpec.describe "マイページ", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  it "ログインした利用者のマイページをキャッシュに保存させない" do
    sign_in user
    get profile_path

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control").split(/,\s*/)).to include("no-store")
  end
end
