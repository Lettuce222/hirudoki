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
      expect(page.evaluate_script(<<~JS)).to be(true)
        (() => {
          const [date, status, quantity, total, address] = [...document.querySelectorAll(".order-details > div")]
            .map(field => field.getBoundingClientRect());
          return date.top === status.top && quantity.top === total.top &&
            date.left === quantity.left && status.left === total.left && date.left < status.left &&
            address.left === date.left && address.right === status.right;
        })()
      JS
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
      menu.bento.update!(description: "だし巻き卵を添えたのり弁当です。")
      File.open(Rails.root.join("app/assets/images/salmon-bento.jpg")) do |photo|
        menu.bento.image.attach(io: photo, filename: "salmon-bento.jpg", content_type: "image/jpeg")
      end
      order = create(:order, user:, daily_menu: menu)
      order.received!
      earlier_order = create(:order, daily_menu: menu)
      earlier_order.received!
      earlier_order.create_review!(rating: 4, comment: "また注文したいです。")
      page.current_window.resize_to(width, height)
      visit profile_path
      click_link menu.bento.name, href: order_path(order)
      click_link "評価投稿"
      expect(page).to have_css(".review-menu img[alt='日替わり弁当']")
      expect(page).to have_text("だし巻き卵を添えたのり弁当です。")
      expect(page).to have_text("#{served_on}・和食")
      expect(page).to have_text("650円（税抜）")
      expect(page).to have_text("平均評価 4.0")
      expect(page).to have_text("また注文したいです。")
      expect(page.evaluate_script(<<~JS, width > 720)).to be(true)
        (() => {
          const menu = document.querySelector(".review-menu").getBoundingClientRect();
          const form = document.querySelector(".review-input").getBoundingClientRect();
          const photo = document.querySelector(".review-menu .menu-photo").getBoundingClientRect();
          return arguments[0] ? form.top === menu.top && form.right < menu.left :
            menu.bottom < form.top && photo.width <= 112;
        })()
      JS
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
