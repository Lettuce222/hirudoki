require "rails_helper"

RSpec.describe RegistrationMailer, type: :mailer do
  let(:invitation) { instance_double(RegistrationInvitation, email: "hana@example.org", signed_link: "sample") }

  it "送信時には起動時に決めた送信元を使う" do
    expected = Mail::Address.new(ENV.fetch("MAIL_FROM", "ひるどき <registration@example.test>"))
    stub_const("ENV", ENV.to_h.merge("MAIL_FROM" => "after-boot@example.org"))

    expect(described_class.confirmation(invitation).from).to eq([ expected.address ])
  end
end
