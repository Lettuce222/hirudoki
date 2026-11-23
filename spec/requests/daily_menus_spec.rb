require "rails_helper"

RSpec.describe "利用者の献立の公開範囲", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { User.create!(name: "花子", email: "hana@example.org", phone: "09012345678", password: "sample-password", password_confirmation: "sample-password") }
  let(:bento) { Bento.create!(name: "非販売のお弁当", category: "和食", on_sale: false, price: 0, display_order: 1) }
  let!(:menu) { DailyMenu.create!(bento: bento, served_on: Date.current, capacity: 1) }

  it "ログイン前に献立一覧や詳細を直接開くとトップに戻る" do
    get daily_menus_path
    expect(response).to redirect_to(root_path)
    get daily_menu_path(menu)
    expect(response).to redirect_to(root_path)
  end

  it "販売を停止した弁当は一覧に出ず、詳細のURLからも閲覧できない" do
    sign_in user
    get daily_menus_path
    expect(response.body).not_to include(bento.name)
    get daily_menu_path(menu)
    expect(response).to have_http_status(:not_found)
  end
end
