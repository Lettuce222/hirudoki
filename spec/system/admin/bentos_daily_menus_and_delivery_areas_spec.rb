require "rails_helper"

RSpec.describe "管理者の弁当・献立・配達エリア管理", type: :system do
  let!(:administrator) { create(:administrator) }
  let(:tags) { %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa] }

  [ [ "PC", 1280, 900 ], [ "スマートフォン", 390, 844 ] ].each do |device, width, height|
    it "#{device}で弁当と献立を登録・編集し、パンくずから配達エリアを管理できる" do
      page.current_window.resize_to(width, height)
      visit "/admin"
      fill_in "メールアドレス", with: administrator.email
      fill_in "パスワード", with: administrator.password
      click_button "ログイン"
      expect(page).not_to have_link("献立登録")
      click_link "弁当", exact: true
      click_link "弁当登録"
      fill_in "弁当名", with: "焼き鮭弁当"
      fill_in "説明", with: "塩焼きの鮭"
      select "和食", from: "タイプ"
      fill_in "税抜価格（円）", with: 650
      attach_file "弁当画像", Rails.root.join("app/assets/images/salmon-bento.jpg")
      expect(page).to have_css("img[alt='選択した弁当画像'][src^='blob:']")
      expect(page).to be_axe_clean.according_to(*tags)
      click_button "保存"
      expect(page).to have_css("table th[scope=col]", text: "税抜価格")
      expect(page).to have_css("table td", text: "650円")
      click_link "編集"
      expect(page).to have_css("img[alt='焼き鮭弁当の登録画像']")
      uncheck "販売中"
      click_button "保存"
      expect(page).to have_text("非販売")
      within("nav[aria-label='パンくず']") { click_link "管理画面" }
      click_link "日別献立"
      click_link "献立登録"
      fill_in "提供日", with: Date.new(2028, 2, 29)
      select "焼き鮭弁当", from: "弁当"
      fill_in "提供数上限（個）", with: 20
      click_button "保存"
      expect(page).to have_css("td", text: "20個")
      expect(page).to be_axe_clean.according_to(*tags)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      within("nav[aria-label='パンくず']") { click_link "管理画面" }
      click_link "配達エリア"
      click_link "配達エリア登録"
      fill_in "エリア名", with: "丸の内"
      fill_in "郵便番号", with: "1000005"
      click_button "保存"
      expect(page).to have_css("td", text: "1000005")
      click_link "編集"
      uncheck "有効"
      click_button "保存"
      expect(page).to have_css("td", text: "無効")
    end
  end
end
