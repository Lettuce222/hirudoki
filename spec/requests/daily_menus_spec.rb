require "rails_helper"

RSpec.describe "利用者の献立の公開範囲", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  it "提供日と弁当タイプ付きのURLを開くと、両方に一致する献立だけが表示される" do
    served_on = Date.new(2026, 11, 25)
    create(:daily_menu, served_on:, bento: create(:bento, name: "鮭弁当", bento_type: "和食"))
    create(:daily_menu, served_on:, bento: create(:bento, name: "パスタ弁当", bento_type: "洋食"))
    create(:daily_menu, served_on: served_on.tomorrow, bento: create(:bento, name: "さば弁当", bento_type: "和食"))
    sign_in user

    get daily_menus_path(served_on:, bento_type: "和食")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("鮭弁当")
    expect(response.body).not_to include("パスタ弁当", "さば弁当")
  end

  it "ログイン前に献立一覧や詳細を直接開くとトップに戻る" do
    get daily_menus_path
    expect(response).to redirect_to(root_path)
    get daily_menu_path(create(:daily_menu))
    expect(response).to redirect_to(root_path)
  end

  it "販売を停止した弁当は一覧に出ず、詳細のURLからも閲覧できない" do
    bento = create(:bento, name: "非販売のお弁当", on_sale: false)
    menu = create(:daily_menu, bento:)
    sign_in user

    get daily_menus_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(bento.name)
    get daily_menu_path(menu)
    expect(response).to have_http_status(:not_found)
  end
end
