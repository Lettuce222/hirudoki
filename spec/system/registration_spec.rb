require "rails_helper"

RSpec.describe "利用者登録", type: :system do
  let(:accessibility_tags) { %i[wcag2a wcag2aa wcag21a wcag21aa wcag22aa] }

  it "スマートフォンでトップから確認メールを経由して登録できる" do
    page.current_window.resize_to(390, 844)
    visit root_path
    click_link "利用者登録"
    expect(page).to be_axe_clean.according_to(*accessibility_tags)
    fill_in "メールアドレス", with: "hana@example.org"
    click_button "確認メール送信"
    expect(page).to have_text("hana@example.org に届いたメール")
    expect(page).to be_axe_clean.according_to(*accessibility_tags)
    url = Nokogiri::HTML(ActionMailer::Base.deliveries.last.html_part.body.decoded).at_css("a")["href"]
    visit URI(url).request_uri
    expect(page).to be_axe_clean.according_to(*accessibility_tags)
    fill_in "氏名", with: "花子"
    fill_in "電話番号", with: "09012345678"
    fill_in "パスワード", with: "sampleパス", exact: true
    fill_in "パスワード（確認）", with: "sampleパス"
    click_button "登録"
    expect(page).to have_text("は半角英数字・記号で入力してください")
    expect(page).to be_axe_clean.according_to(*accessibility_tags)
    fill_in "パスワード", with: "sample-password", exact: true
    fill_in "パスワード（確認）", with: "sample-password"
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    click_button "登録"
    expect(page).to have_text("利用者登録が完了しました。")
    expect(page).to have_text("マイページ")
    expect(page).to have_text("花子")
    expect(page).to be_axe_clean.according_to(*accessibility_tags)
  end
end
