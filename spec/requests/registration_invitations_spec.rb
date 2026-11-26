require "rails_helper"

RSpec.describe "登録確認メール", type: :request do
  it "確認メールを送り、利用者レコードは作成しない" do
    expect { post registration_invitation_path, params: { email: "hana@example.org" } }.not_to change(User, :count)
    expect(response).to redirect_to(registration_invitation_path)
    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq([ "hana@example.org" ])
    link = Nokogiri::HTML(mail.html_part.body.decoded).at_css("a")["href"]
    invitation = RegistrationInvitation.find_by!(email: "hana@example.org")
    uri = URI(link)
    expect(uri.path).to eq(new_registration_path)
    token = URI.decode_www_form(uri.query).to_h.fetch("token")
    expect(RegistrationInvitation.from_link(token)).to eq(invitation)
  end

  it "メールアドレスに誤りがあれば送信せず入力画面に戻す" do
    expect { post registration_invitation_path, params: { email: "invalid" } }.not_to change { ActionMailer::Base.deliveries.size }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("有効なメールアドレスを入力してください")
  end
end
