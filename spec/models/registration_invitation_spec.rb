require "rails_helper"

RSpec.describe RegistrationInvitation, type: :model do
  let(:address) { "hana@example.org" }
  let(:details) { { name: "花子", phone: "09012345678", password: "sample-password", password_confirmation: "sample-password" } }

  before { freeze_time }

  it "再送間隔が過ぎるまでは同じアドレスにメールを追加送信しない" do
    expect {
      described_class.deliver_to!(" HANA@example.org ")
      described_class.deliver_to!(address)
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end

  it "再送すると古いリンクは使えず、新しいリンクで一度だけ登録できる" do
    first = described_class.deliver_to!(address).signed_link
    travel 60.seconds
    last = described_class.deliver_to!(address).signed_link
    expect(described_class.from_link(first)).to be_nil
    user = described_class.register!(last, details)
    expect(user).to be_persisted
    expect(user.valid_password?("sample-password")).to be(true)
    expect(described_class.from_link(last)).to be_nil
  end

  it "初回の発行・最終送信・登録の日時を利用者に紐づけて残す" do
    invitation = described_class.deliver_to!(address)
    issued_at = invitation.created_at
    expect(invitation.sent_at).to eq(Time.current)
    travel 2.minutes
    token = described_class.deliver_to!(address).signed_link
    sent_at = Time.current
    travel 5.minutes
    user = described_class.register!(token, details)

    invitation.reload
    expect(invitation.created_at).to eq(issued_at)
    expect(invitation.sent_at).to eq(sent_at)
    expect(invitation.user).to eq(user)
    expect(invitation.user.created_at).to eq(Time.current)
    expect { described_class.register!(token, details) }.to raise_error(ActiveRecord::RecordNotFound)
    expect { described_class.deliver_to!(address) }.not_to change { invitation.reload.sent_at }
  end

  it "登録済みのアドレスへの再申請でメールや利用者を増やさない" do
    existing = User.create!(details.merge(email: address))
    expect { described_class.deliver_to!(address.upcase) }.not_to change { ActionMailer::Base.deliveries.size }
    expect(described_class.exists?(email: address)).to be(false)
    expect(User.new(details.merge(email: address.upcase))).not_to be_valid
    expect(existing.encrypted_password).not_to eq(details[:password])
  end

  it "古いフォームを送信しても再送後のリンクを消費しない" do
    invitation = described_class.deliver_to!(address)
    old_link = invitation.signed_link
    travel 1.minute
    new_link = described_class.deliver_to!(address).signed_link
    expect { described_class.register!(old_link, details) }.to raise_error(ActiveRecord::RecordNotFound)
    expect(described_class.from_link(new_link)).to be_present
  end

  it "送信から30分経過するとリンクが失効する" do
    token = described_class.deliver_to!(address).signed_link
    travel 30.minutes + 1.second
    expect(described_class.from_link(token)).to be_nil
  end

  it "再送できなかった場合は以前に受け取ったリンクを使える" do
    token = described_class.deliver_to!(address).signed_link
    travel 1.minute
    allow(RegistrationMailer).to receive(:confirmation).and_raise(Net::ReadTimeout)
    expect { described_class.deliver_to!(address) }.to raise_error(Net::ReadTimeout)
    expect(described_class.from_link(token)).to be_present
  end
end
