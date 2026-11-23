require "rails_helper"

RSpec.describe "利用者のログインとログアウト", type: :system do
  let!(:user) { User.create!(name: "花子", email: "hana@example.org", phone: "09012345678", password: "sample-password", password_confirmation: "sample-password") }
  let(:accessibility_tags) { %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa] }

  [ [ "PC", 1280, 900 ], [ "スマートフォン", 390, 844 ] ].each do |device, width, height|
    it "#{device}で登録済みの利用者が再ログインし、ログアウト後はマイページを開けない" do
      page.current_window.resize_to(width, height)
      visit root_path
      click_link "ログイン"
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: "wrong-password"
      click_button "ログイン"
      expect(page).to have_text("メールアドレスまたはパスワードが正しくありません。")
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: "sample-password"
      click_button "ログイン"
      expect(page).to have_current_path(profile_path)
      expect(page).to have_text(user.name)
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      click_button "ログアウト"
      expect(page).to have_current_path(root_path)
      expect(page).to have_text("ログアウトしました。")
      visit profile_path
      expect(page).to have_current_path(root_path)
      expect(page).to have_link("ログイン")
    end
  end
end
