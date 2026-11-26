require "rails_helper"

RSpec.describe "管理者ログイン", type: :system do
  let(:administrator) { create(:administrator) }
  let(:accessibility_tags) { %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa] }

  [ [ "PC", 1280, 900 ], [ "スマートフォン", 390, 844 ] ].each do |device, width, height|
    it "#{device}で管理用URLからログインし、ログアウトすると管理者ログインに戻る" do
      page.current_window.resize_to(width, height)
      visit "/admin"
      expect(page).to have_css("h1", text: "管理者ログイン")
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      fill_in "メールアドレス", with: administrator.email
      fill_in "パスワード", with: administrator.password
      click_button "ログイン"
      expect(page).to have_css("h1", text: "管理画面")
      expect(page).to have_no_text(administrator.name)
      expect(page).to be_axe_clean.according_to(*accessibility_tags)
      click_button "ログアウト"
      expect(page).to have_css("h1", text: "管理者ログイン")
      expect(page).to have_text("ログアウトしました。")
      visit "/admin"
      expect(page).to have_css("h1", text: "管理者ログイン")
    end
  end

  it "シードを再実行しても管理者は作成時のパスワードでログインできる" do
    stub_const("ENV", ENV.to_h.merge("SEED_ADMIN_EMAIL" => "ADMIN@example.test", "SEED_ADMIN_PASSWORD" => "before-change", "SEED_ADMIN_NAME" => "管理担当"))
    expect { Rails.application.load_seed }.to change(Administrator, :count).by(1)
    seeded_administrator = Administrator.find_by!(email: "admin@example.test")
    expect(seeded_administrator.encrypted_password).not_to eq("before-change")

    ENV["SEED_ADMIN_PASSWORD"] = "after-change"
    expect { Rails.application.load_seed }.not_to change(Administrator, :count)

    visit "/admin"
    fill_in "メールアドレス", with: seeded_administrator.email
    fill_in "パスワード", with: "before-change"
    click_button "ログイン"

    expect(page).to have_current_path(admin_root_path)
    expect(page).to have_css("h1", text: "管理画面")
  end
end
