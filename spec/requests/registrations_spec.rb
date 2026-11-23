require "rails_helper"

RSpec.describe "メール確認による利用者登録", type: :request do
  let(:details) { { name: "花子", phone: "09012345678", password: "sample-password", password_confirmation: "sample-password" } }

  it "最新のメールのリンクで入力し、確認済みのアドレスで登録してマイページを開く" do
    expect { post registration_invitation_path, params: { email: "hana@example.org" } }.not_to change(User, :count)
    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq([ "hana@example.org" ])
    url = Nokogiri::HTML(mail.html_part.body.decoded).at_css("a")["href"]
    get URI(url).request_uri
    token = Nokogiri::HTML(response.body).at_css("input[name=token]")["value"]
    post registration_path, params: { token:, user: details.merge(phone: "") }
    expect(response).to have_http_status(:unprocessable_content)
    expect { post registration_path, params: { token:, user: details.merge(email: "other@example.org") } }.to change(User, :count).by(1)
    follow_redirect!
    expect(response.body).to include("マイページ", "hana@example.org", "花子")
    expect { post registration_path, params: { token:, user: details } }.not_to change(User, :count)
  end

  it "メールアドレスに誤りがあれば送信せず入力画面に戻す" do
    expect { post registration_invitation_path, params: { email: "invalid" } }.not_to change { ActionMailer::Base.deliveries.size }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("有効なメールアドレスを入力してください")
  end

  it "トークンが欠けていると確認メールの再申請を案内する" do
    get new_registration_path
    expect(response).to redirect_to(new_registration_invitation_path)

    expect { post registration_path, params: { user: details } }.not_to change(User, :count)
    expect(response).to redirect_to(new_registration_invitation_path)
    follow_redirect!
    expect(response.body).to include("確認メールを再度お申し込みください")
  end

  it "未確認の利用者は登録もマイページの閲覧もできない" do
    expect { post registration_path, params: { token: "invalid", user: details } }.not_to change(User, :count)
    expect(response).to redirect_to(new_registration_invitation_path)
    get profile_path
    expect(response).to redirect_to(root_path)
  end
end
