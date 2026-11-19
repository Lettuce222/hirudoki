require "rails_helper"

RSpec.describe User, type: :model do
  def user_with_password(password)
    described_class.new(name: "花子", email: "hana@example.org", phone: "09012345678",
                        password: password, password_confirmation: password)
  end

  it "半角英数字・記号の6文字から72文字までを使える" do
    expect(user_with_password("Az09!~")).to be_valid
    expect(user_with_password("a" * 72)).to be_valid
    expect(user_with_password("a" * 5)).not_to be_valid
    expect(user_with_password("a" * 73)).not_to be_valid
  end

  it "全角文字、半角カナ、空白、改行はパスワードに使えない" do
    [ "あ", "ｶ", " ", "\t", "\n", "🍱" ].each do |character|
      user = user_with_password("sample" + character)
      user.validate
      expect(user.errors[:password]).to include("は半角英数字・記号で入力してください（空白は使えません）")
    end
  end
end
