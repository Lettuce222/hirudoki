require "rails_helper"

RSpec.describe RegistrationsController, type: :request do
  let(:details) { attributes_for(:user).except(:email) }

  it "確認リンクから確認済みのアドレスで登録できる" do
    invitation = RegistrationInvitation.create!(email: "hana@example.org", sent_at: Time.utc(2028, 2, 28))
    token = invitation.signed_link
    get new_registration_path(token:)
    expect(response.body).to include("hana@example.org")
    post registration_path, params: { token:, user: details.merge(phone: "") }
    expect(response).to have_http_status(:unprocessable_content)
    expect { post registration_path, params: { token:, user: details.merge(email: "other@example.org") } }.to change(User, :count).by(1)
    follow_redirect!
    expect(response.body).to include("マイページ", "hana@example.org", details.fetch(:name))
    expect { post registration_path, params: { token:, user: details } }.not_to change(User, :count)
  end

  it "トークンが欠けていると確認メールの再申請を案内する" do
    get new_registration_path
    expect(response).to redirect_to(new_registration_invitation_path)

    expect { post registration_path, params: { user: details } }.not_to change(User, :count)
    expect(response).to redirect_to(new_registration_invitation_path)
    follow_redirect!
    expect(response.body).to include("確認メールを再度お申し込みください")
  end

  it "無効な確認リンクでは登録できない" do
    expect { post registration_path, params: { token: "invalid", user: details } }.not_to change(User, :count)
    expect(response).to redirect_to(new_registration_invitation_path)
  end
end
