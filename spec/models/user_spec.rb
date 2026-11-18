require "rails_helper"

RSpec.describe User, type: :model do
  def user_with_password(password)
    described_class.new(name: "花子", email: "hana@example.org", phone: "09012345678",
                        password: password, password_confirmation: password)
  end

  it "半角英数字72文字とひらがな24文字を登録に使える" do
    expect(user_with_password("a" * 72)).to be_valid
    expect(user_with_password("あ" * 24)).to be_valid
  end

  it "使える長さを超えたら末尾から減らす文字数を利用者に伝える" do
    user = user_with_password("あ" * 23 + "🍱" + "a")
    user.validate
    expect(user.errors[:password]).to include("が長すぎます。入力したパスワードの末尾を2文字以上短くしてください。")
  end

  it "複数のコードポイントからなる絵文字も画面で見える1文字として数える" do
    user = user_with_password("a" * 70 + "👩‍🍳")
    user.validate
    expect(user.errors[:password]).to include("が長すぎます。入力したパスワードの末尾を1文字以上短くしてください。")
  end
end
