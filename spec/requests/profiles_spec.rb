require "rails_helper"

RSpec.describe ProfilesController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  it "ログインした利用者のマイページをキャッシュに保存させない" do
    sign_in user
    get profile_path

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control").split(/,\s*/)).to include("no-store")
  end

  it "管理者セッションだけではマイページを開けない" do
    sign_in create(:administrator)
    get profile_path
    expect(response).to redirect_to(root_path)
  end

  it "別の利用者IDを指定してもログイン中の利用者だけを表示する" do
    other = create(:user)
    sign_in user
    get profile_path, params: { id: other.id }
    expect(response.body).to include(user.email)
    expect(response.body).not_to include(other.email)
  end

  it "別の利用者の注文を表示しない" do
    menu = create(:daily_menu, served_on: Date.new(2028, 2, 29))
    travel_to(Time.utc(2028, 2, 28)) do
      create(:order, daily_menu: menu, delivery_address: "駅前一丁目")
    end

    sign_in user
    get profile_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("駅前一丁目")
  end
end
