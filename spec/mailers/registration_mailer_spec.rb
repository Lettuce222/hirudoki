require "rails_helper"

RSpec.describe RegistrationMailer, type: :mailer do
  let(:invitation) { instance_double(RegistrationInvitation, email: "hana@example.org", signed_link: "sample") }

  it "MAIL_FROMのアドレスを送信元に使う" do
    stub_const("ENV", ENV.to_h.merge("MAIL_FROM" => "sender@example.org"))
    expect(described_class.confirmation(invitation).from).to eq([ "sender@example.org" ])
  end

  it "MAIL_FROMが未設定なら開発用の送信元を使う" do
    stub_const("ENV", ENV.to_h.except("MAIL_FROM"))
    expect(described_class.confirmation(invitation).from).to eq([ "registration@example.test" ])
  end
end
