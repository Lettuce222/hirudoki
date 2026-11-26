require "rails_helper"

RSpec.describe "利用者のログインとログアウト", type: :system do
  let!(:user) { create(:user) }
  let(:accessibility_tags) { %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa] }

  it "端末がダーク配色でもメールアドレスとパスワードの入力欄を白く表示する" do
    browser = page.driver.browser
    browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-color-scheme", value: "dark" } ])
    visit new_user_session_path

    email_background = page.evaluate_script("getComputedStyle(arguments[0]).backgroundColor", find_field("メールアドレス"))
    password_background = page.evaluate_script("getComputedStyle(arguments[0]).backgroundColor", find_field("パスワード"))
    expect([ email_background, password_background ]).to eq([ "rgb(255, 255, 255)", "rgb(255, 255, 255)" ])
    expect(page).to be_axe_clean.according_to(*accessibility_tags)
  ensure
    browser&.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  [ [ "PC", 1280, 900 ], [ "スマートフォン", 390, 844 ] ].each do |device, width, height|
    it "#{device}で登録済みの利用者が再ログインし、ログアウト後はマイページを開けない" do
      page.current_window.resize_to(width, height)
      visit root_path
      click_link "ひるどき"
      expect(page).to have_current_path(new_user_session_path)
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: "wrong-password"
      click_button "ログイン"
      expect(page).to have_text("メールアドレスまたはパスワードが正しくありません。")
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: user.password
      click_button "ログイン"
      expect(page).to have_current_path(daily_menus_path)
      click_link "定期注文設定"
      expect(page).to have_current_path(recurring_order_settings_path)
      click_link "ひるどき"
      expect(page).to have_current_path(daily_menus_path)
      click_link "マイページ"
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
