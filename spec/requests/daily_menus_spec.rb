require "rails_helper"

RSpec.describe DailyMenusController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  it "絞り込みなしで一覧を開くと、提供日やタイプが異なる販売中の献立が表示される" do
    create(:daily_menu, served_on: Date.new(2028, 2, 29), bento: create(:bento, name: "鮭弁当", bento_type: "和食"))
    create(:daily_menu, served_on: Date.new(2028, 3, 1), bento: create(:bento, name: "パスタ弁当", bento_type: "洋食"))
    sign_in user

    get daily_menus_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("鮭弁当", "パスタ弁当")
  end

  it "提供日と弁当タイプ付きのURLを開くと、両方に一致する献立だけが表示される" do
    served_on = Date.new(2028, 2, 29)
    create(:daily_menu, served_on:, bento: create(:bento, name: "鮭弁当", bento_type: "和食"))
    create(:daily_menu, served_on:, bento: create(:bento, name: "パスタ弁当", bento_type: "洋食"))
    create(:daily_menu, served_on: served_on.tomorrow, bento: create(:bento, name: "さば弁当", bento_type: "和食"))
    sign_in user

    get daily_menus_path(served_on:, bento_type: "和食")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("鮭弁当")
    expect(response.body).not_to include("パスタ弁当", "さば弁当")
  end

  context "絞り込み後の献立が20件を超える場合" do
    let(:first_day) { Date.new(2028, 2, 29) }
    let(:salmon) { create(:bento, bento_type: "和食") }

    before do
      21.times { |offset| create(:daily_menu, bento: salmon, served_on: first_day + offset) }
      create(:daily_menu, bento: create(:bento, bento_type: "洋食"), served_on: first_day)
      sign_in user
    end

    it "最初の20件を表示し、次ページに絞り込み条件を引き継ぐ" do
      get daily_menus_path, params: { bento_type: "和食" }

      document = Capybara.string(response.body)
      expect(document).to have_css("tbody tr", count: 20)
      expect(document).to have_link("次へ", href: daily_menus_path(bento_type: "和食", page: 2))
    end

    it "最後のページに残りの献立を表示する" do
      get daily_menus_path, params: { bento_type: "和食", page: 2 }

      document = Capybara.string(response.body)
      expect(document).to have_css("tbody tr", count: 1, text: (first_day + 20).iso8601)
      expect(document).to have_no_link("次へ")
    end
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
