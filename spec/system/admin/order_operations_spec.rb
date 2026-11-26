require "rails_helper"

RSpec.describe "管理者の注文・日別リスト・請求額の確認", type: :system do
  let(:administrator) { create(:administrator) }
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:accessibility_tags) { %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa] }

  [ [ "PC", 1280, 900 ], [ "スマートフォン", 390, 844 ] ].each do |device, width, height|
    it "#{device}で注文をキャンセルし、日別リストと月別請求に反映されたことを確認できる" do
      order = travel_to(Time.zone.local(2028, 2, 28, 9)) do
        menu = create(:daily_menu, served_on:)
        create(:order, daily_menu: menu, user: create(:user, name: "太郎"))
        create(:order, daily_menu: menu, quantity: 2)
      end
      page.current_window.resize_to(width, height)
      visit admin_root_path
      fill_in "メールアドレス", with: administrator.email
      fill_in "パスワード", with: administrator.password
      click_button "ログイン"
      click_link "注文一覧"
      expect(page).to have_css("h1", text: "注文一覧")
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      click_link "注文 ##{order.id}"
      expect(page).to have_select("注文状態", selected: "注文済")
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      select "キャンセル済", from: "注文状態"
      click_button "保存"
      expect(page).to have_text("注文状態を保存しました。")
      expect(page).to have_select("注文状態", selected: "キャンセル済")

      within("nav[aria-label='パンくず']") { click_link "管理画面" }
      click_link "製造・配達リスト"
      fill_in "提供日", with: served_on
      click_button "表示"
      expect(page).to have_current_path(/served_on=2028-02-29/)
      within("[aria-label='製造リスト']") { expect(page).to have_css("td", text: "1個") }
      within("[aria-label='配達リスト']") do
        expect(page).to have_css("tbody tr", count: 1)
        expect(page).not_to have_link("注文 ##{order.id}")
      end
      expect(page).to be_axe_clean.according_to(*accessibility_tags)

      within("nav[aria-label='パンくず']") { click_link "管理画面" }
      click_link "利用者一覧"
      expect(page).to have_css("h1", text: "利用者一覧")
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      click_link order.user.name
      page.execute_script("arguments[0].value = arguments[1]", find_field("請求月"), "2028-02")
      click_button "表示"
      expect(page).to have_text("2028年02月の請求額")
      expect(page).to have_text("税込0円")
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
    end
  end
end
