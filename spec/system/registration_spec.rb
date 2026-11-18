require "rails_helper"

RSpec.describe "利用者登録", type: :system do
  it "スマートフォンでトップから確認メールを経由して登録できる" do
    page.current_window.resize_to(390, 844)
    visit root_path
    click_link "利用者登録"
    fill_in "メールアドレス", with: "hana@example.org"
    click_button "確認メール送信"
    expect(page).to have_text("hana@example.org に届いたメール")
    url = Nokogiri::HTML(ActionMailer::Base.deliveries.last.html_part.body.decoded).at_css("a")["href"]
    visit URI(url).request_uri
    fill_in "氏名", with: "花子"
    fill_in "電話番号", with: "09012345678"
    fill_in "パスワード", with: "sample-password", exact: true
    fill_in "パスワード（確認）", with: "sample-password"
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    click_button "登録"
    expect(page).to have_text("利用者登録が完了しました。")
    expect(page).to have_text("マイページ")
    expect(page).to have_text("花子")
  end
end
