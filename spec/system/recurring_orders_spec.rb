require "rails_helper"

RSpec.describe "定期注文の設定と生成", type: :system do
  let(:user) { create(:user, name: "太郎") }
  let(:administrator) { create(:administrator) }
  let(:area) { create(:delivery_area, name: "駅前") }
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:accessibility_tags) { %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa] }

  before do
    create(:delivery_area, name: "休止エリア", active: false)
    create(:recurring_order_setting, user: create(:user, name: "花子"), delivery_area: area, bento_type: "洋食")
  end

  [ [ "PC", 1280, 900 ], [ "スマートフォン", 390, 844 ] ].each do |device, width, height|
    it "#{device}で定期注文設定を保存し、生成件数とスキップ理由を確認できる" do
      travel_to(Time.zone.local(2028, 2, 28, 9)) do
        create(:daily_menu, served_on:)
        page.current_window.resize_to(width, height)
        visit new_user_session_path
        fill_in "メールアドレス", with: user.email
        fill_in "パスワード", with: user.password
        click_button "ログイン"
        expect(page).to have_current_path(profile_path)
        click_link "定期注文設定"
        click_link "定期設定登録"
        expect(page).to have_select("曜日", options: %w[曜日を選択 月曜日 火曜日 水曜日 木曜日 金曜日])
        expect(page).to have_select("配達エリア", options: [ "配達エリアを選択", area.name ])
        select "火曜日", from: "曜日"
        select "和食", from: "弁当タイプ"
        select "2", from: "個数"
        select area.name, from: "配達エリア"
        fill_in "配達先住所", with: "駅前一丁目3番地"
        expect(page).to be_axe_clean.according_to(*accessibility_tags)
        click_button "保存"
        expect(page).to have_text("和食・2個・有効")
        expect(page).to be_axe_clean.according_to(*accessibility_tags)

        visit admin_root_path
        fill_in "メールアドレス", with: administrator.email
        fill_in "パスワード", with: administrator.password
        click_button "ログイン"
        click_link "定期注文生成"
        fill_in "提供日", with: served_on
        click_button "定期注文生成"
        expect(page).to have_text("生成 1件・スキップ 1件")
        expect(page).to have_css("tr", text: "花子 販売中の献立がありません。")
        expect(page).to be_axe_clean.according_to(*accessibility_tags)

        click_button "定期注文生成"
        expect(page).to have_text("生成 0件・スキップ 2件")
        expect(page).to have_css("tr", text: "太郎 この対象日は生成済みです。")

        visit profile_path
        expect(page).to have_text("2028-02-29 提供・2個")
        expect(page).to have_text("駅前一丁目3番地")
        click_link "定期注文設定"
        click_link "火曜日の設定を編集"
        select "無効", from: "設定の状態"
        click_button "保存"
        expect(page).to have_text("和食・2個・無効")
      end
    end
  end
end
