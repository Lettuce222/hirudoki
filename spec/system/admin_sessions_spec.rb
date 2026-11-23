require "rails_helper"

RSpec.describe "管理者ログイン", type: :system do
  let!(:administrator) { Administrator.create!(name: "管理担当", email: "admin@example.test", password: "sample-password") }
  let(:accessibility_tags) { %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa] }

  [ [ "PC", 1280, 900 ], [ "スマートフォン", 390, 844 ] ].each do |device, width, height|
    it "#{device}で管理用URLからログインし、ログアウトすると管理者ログインに戻る" do
      page.current_window.resize_to(width, height)
      visit "/admin"
      expect(page).to have_css("h1", text: "管理者ログイン")
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      fill_in "メールアドレス", with: administrator.email
      fill_in "パスワード", with: "sample-password"
      click_button "ログイン"
      expect(page).to have_css("h1", text: "管理画面")
      expect(page).to have_text(administrator.name)
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      click_button "ログアウト"
      expect(page).to have_css("h1", text: "管理者ログイン")
      expect(page).to have_text("ログアウトしました。")
      visit "/admin"
      expect(page).to have_css("h1", text: "管理者ログイン")
    end
  end
end
