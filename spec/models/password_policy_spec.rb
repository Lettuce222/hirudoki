require "rails_helper"

RSpec.describe "アカウントのパスワード", type: :model do
  %i[user administrator].each do |factory|
    context factory.to_s do
      it "半角英数字・記号の6文字から72文字までを使える" do
        [ "Az09!~", "a" * 72 ].each do |password|
          expect(build(factory, password:)).to be_valid
        end
        [ "a" * 5, "a" * 73 ].each do |password|
          account = build(factory, password:)
          expect(account).not_to be_valid
          expect(account.errors[:password]).to be_present
        end
      end

      it "全角文字、半角カナ、空白、改行はパスワードに使えない" do
        [ "あ", "ｶ", " ", "\t", "\n", "🍱" ].each do |character|
          account = build(factory, password: "sample" + character)
          account.validate
          expect(account.errors[:password]).to include("は半角英数字・記号で入力してください（空白は使えません）")
        end
      end
    end
  end
end
