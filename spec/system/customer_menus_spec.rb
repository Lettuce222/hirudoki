require "rails_helper"

RSpec.describe "利用者の献立閲覧", type: :system do
  include Warden::Test::Helpers

  let(:user) { User.create!(name: "花子", email: "hana@example.org", phone: "09012345678", password: "sample-password", password_confirmation: "sample-password") }
  let(:date) { Date.new(2026, 11, 24) }
  let(:salmon) { Bento.create!(name: "焼き鮭のり弁当", category: "和食", description: "焼き鮭と玉子焼きです。", price: 650, display_order: 1) }
  let(:pasta) { Bento.create!(name: "パスタ弁当", category: "洋食", price: 720, display_order: 2) }
  let(:accessibility_tags) { %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa] }

  before do
    File.open(Rails.root.join("app/assets/images/salmon-bento.jpg")) do |file|
      salmon.image.attach(io: file, filename: "salmon.jpg", content_type: "image/jpeg")
    end
    DailyMenu.create!(bento: salmon, served_on: date, capacity: 19)
    DailyMenu.create!(bento: pasta, served_on: date, capacity: 10)
    DailyMenu.create!(bento: salmon, served_on: date.tomorrow, capacity: 4)
    login_as(user, scope: :user)
  end

  after { Warden.test_reset! }

  [ [ "PC", 1280, 900 ], [ "スマートフォン", 390, 844 ] ].each do |device, width, height|
    it "#{device}でマイページから献立を探し、弁当詳細と評価欄を確認できる" do
      page.current_window.resize_to(width, height)
      visit profile_path
      click_link "献立一覧"
      expect(page).to have_table("献立一覧")
      expect(page).to have_css("tbody tr", count: 3)
      expect(page).to have_css("tbody img", count: 2)
      expect(page).to have_css("[aria-label='お弁当箱のイラスト']", count: 1)
      expect(page.evaluate_script(<<~JS)).to be(true)
        (() => {
          const [photo, drawing] = [...document.querySelectorAll("tbody tr")].slice(0, 2).map(row => row.cells[0].firstElementChild.getBoundingClientRect());
          const date = document.querySelector("input[type=date]").getBoundingClientRect();
          const type = document.querySelector("select").getBoundingClientRect();
          return photo.width === drawing.width && photo.height === drawing.height &&
            date.top === type.top && date.height === 48 && type.height === 48 &&
            document.documentElement.scrollWidth <= innerWidth;
        })()
      JS
      expect(page).to be_axe_clean.according_to(*accessibility_tags)

      fill_in "提供日", with: date
      select "和食", from: "弁当タイプ"
      click_button "絞り込み"
      expect(page).to have_css("tbody tr", count: 1)
      within("tbody") { click_link "焼き鮭のり弁当" }
      expect(page).to have_text("焼き鮭と玉子焼きです。")
      expect(page).to have_text("650円（税抜）")
      expect(page).to have_text("残り19個")
      expect(page).to have_text("まだ評価はありません。")
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      within("nav[aria-label='パンくず']") { click_link "献立一覧" }
      expect(page).to have_select("弁当タイプ", selected: "和食")
      expect(page).to have_css("tbody tr", count: 1)
      select "ヘルシー", from: "弁当タイプ"
      click_button "絞り込み"
      expect(page).to have_text("条件に合う献立はありません。")
    end
  end
end
