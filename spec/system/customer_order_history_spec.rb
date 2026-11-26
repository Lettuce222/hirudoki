require "rails_helper"

RSpec.describe "利用者の注文履歴と評価", type: :system do
  include Warden::Test::Helpers

  let(:user) { create(:user) }
  let(:area) { create(:delivery_area) }
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:menu) { create(:daily_menu, served_on:, capacity: 3) }
  let(:setting) { create(:recurring_order_setting, user:, delivery_area: area) }
  let(:tags) { %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa] }

  around { |example| travel_to(Time.zone.local(2028, 2, 29, 9), &example) }

  before { login_as(user, scope: :user) }
  after { Warden.test_reset! }

  [ [ "PC", 1280, 900 ], [ "スマートフォン", 390, 844 ] ].each do |device, width, height|
    it "#{device}で定期注文の個数を変更し、キャンセルすると残数が戻る" do
      order = create(:order, user:, daily_menu: menu, delivery_area: area, recurring_order_setting: setting)
      page.current_window.resize_to(width, height)
      visit profile_path
      click_link menu.bento.name, href: order_path(order)
      expect(page).to have_current_path(order_path(order))
      expect(page).to have_text("定期")
      expect(page.evaluate_script(<<~JS, find_link("個数変更"), find_button("注文キャンセル"))).to be(true)
        (() => {
          const edit = arguments[0].getBoundingClientRect();
          const cancel = arguments[1].getBoundingClientRect();
          return edit.height === cancel.height && edit.top === cancel.top;
        })()
      JS
      expect(page.evaluate_script("document.documentElement.scrollWidth")).to be <= width
      expect(page).to be_axe_clean.according_to(*tags)

      click_link "個数変更"
      select "2個（税込1,296円）", from: "変更後の個数"
      click_button "保存"
      expect(page).to have_current_path(order_path(order))
      expect(page).to have_text("個数を変更しました。")
      expect(page).to have_text("税込1,296円")

      dismiss_confirm("この注文をキャンセルしますか？") { click_button "注文キャンセル" }
      expect(page).to have_current_path(order_path(order))
      expect(page).to have_no_text("キャンセル済")

      accept_confirm("この注文をキャンセルしますか？") { click_button "注文キャンセル" }
      expect(page).to have_current_path(order_path(order))
      expect(page).to have_text("キャンセル済")
      expect(page).to have_no_link("個数変更")
      expect(page).to have_no_button("注文キャンセル")
      visit daily_menu_path(menu)
      expect(page).to have_text("残り3個")
    end

    it "#{device}で受取済みの注文の評価を投稿し、献立詳細の平均評価とコメントを確認できる" do
      order = create(:order, user:, daily_menu: menu)
      order.received!
      earlier_order = create(:order, daily_menu: menu)
      earlier_order.received!
      earlier_order.create_review!(rating: 4, comment: "また注文したいです。")
      page.current_window.resize_to(width, height)
      visit profile_path
      click_link menu.bento.name, href: order_path(order)
      click_link "評価投稿"
      select "5点", from: "評価"
      fill_in "コメント（任意）", with: "おいしかったです。"
      expect(page.evaluate_script("document.documentElement.scrollWidth")).to be <= width
      expect(page).to be_axe_clean.according_to(*tags)
      click_button "評価投稿"
      expect(page).to have_text("評価を投稿しました。")
      expect(page).to have_no_link("評価投稿")

      click_link "献立の評価を見る"
      expect(page).to have_text("平均評価 4.5")
      expect(page).to have_text("おいしかったです。")
      expect(page).to have_text("また注文したいです。")
      expect(page).to be_axe_clean.according_to(*tags)
    end
  end
end
