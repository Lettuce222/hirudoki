require "rails_helper"

RSpec.describe "手動注文", type: :system do
  include Warden::Test::Helpers

  after { Warden.test_reset! }

  [ [ "PC", 1280, 900 ], [ "スマートフォン", 390, 844 ] ].each do |device, width, height|
    it "#{device}で献立を選んで注文し、マイページで数量・金額・配達先を確認できる" do
      travel_to(Time.utc(2028, 2, 28)) do
        menu = create(:daily_menu, served_on: Date.new(2028, 2, 29), capacity: 3)
        area = create(:delivery_area, name: "駅前")
        create(:delivery_area, name: "受付休止", active: false)
        login_as(create(:user), scope: :user)
        page.current_window.resize_to(width, height)
        visit daily_menu_path(menu)
        contrast = be_axe_clean.within("a.primary").checking_only("color-contrast").audit(page)
        expect(contrast.results.passes.map(&:id)).to include(:"color-contrast")
        click_link "注文手続き"
        expect(page).to have_field("配達先住所", with: "")
        expect(page).to have_select("配達エリア", selected: "選択してください")
        expect(page).to have_no_select("配達エリア", with_options: [ "受付休止" ])
        select "2個（税込1,404円）", from: "個数"
        select area.name, from: "配達エリア"
        fill_in "配達先住所", with: "駅前一丁目3番地"
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
        click_button "注文確定"
        expect(page).to have_current_path(profile_path)
        expect(page).to have_text("注文済")
        expect(page).to have_text("2個")
        expect(page).to have_text("1,404円")
        expect(page).to have_text("駅前一丁目3番地")
        visit new_daily_menu_order_path(menu)
        expect(page).to have_field("配達先住所", with: "駅前一丁目3番地")
        expect(page).to have_select("配達エリア", selected: area.name)
        visit daily_menus_path
        expect(page).to have_css("td", text: "1個")
      end
    end
  end
end
