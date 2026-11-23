require "rails_helper"

RSpec.describe User, type: :model do
  it "半角英数字・記号の6文字から72文字までを使える" do
    expect(build(:user, password: "Az09!~")).to be_valid
    expect(build(:user, password: "a" * 72)).to be_valid
    expect(build(:user, password: "a" * 5)).not_to be_valid
    expect(build(:user, password: "a" * 73)).not_to be_valid
  end

  it "全角文字、半角カナ、空白、改行はパスワードに使えない" do
    [ "あ", "ｶ", " ", "\t", "\n", "🍱" ].each do |character|
      user = build(:user, password: "sample" + character)
      user.validate
      expect(user.errors[:password]).to include("は半角英数字・記号で入力してください（空白は使えません）")
    end
  end
end
