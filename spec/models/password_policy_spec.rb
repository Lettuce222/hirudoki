require "rails_helper"

RSpec.describe "アカウントのパスワード", type: :model do
  { User => { phone: "09012345678" }, Administrator => {} }.each do |model, extra_attributes|
    context model.name do
      let(:account) { model.new(name: "花子", email: "hana@example.org", **extra_attributes) }

      def set_password(password)
        account.password = account.password_confirmation = password
      end

      it "半角英数字・記号の6文字から72文字までを使える" do
        [ "Az09!~", "a" * 72 ].each do |password|
          set_password(password)
          expect(account).to be_valid
        end
        [ "a" * 5, "a" * 73 ].each do |password|
          set_password(password)
          expect(account).not_to be_valid
          expect(account.errors[:password]).to be_present
        end
      end

      it "全角文字、半角カナ、空白、改行はパスワードに使えない" do
        [ "あ", "ｶ", " ", "\t", "\n", "🍱" ].each do |character|
          set_password("sample" + character)
          account.validate
          expect(account.errors[:password]).to include("は半角英数字・記号で入力してください（空白は使えません）")
        end
      end
    end
  end
end
