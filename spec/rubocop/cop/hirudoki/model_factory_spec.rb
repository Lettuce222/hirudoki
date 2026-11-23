require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../lib/rubocop/cop/hirudoki/model_factory"

RSpec.describe RuboCop::Cop::Hirudoki::ModelFactory, :config do
  let(:cop_config) { { "Models" => [ "User" ] } }

  it "factoryを用意したモデルを直接生成すると指摘する" do
    expect_offense(<<~RUBY)
      User.new
           ^^^ Use Factory Bot to build or create test records.
      ::User.create!
             ^^^^^^^ Use Factory Bot to build or create test records.
    RUBY
  end

  it "モデルのspecでdescribed_classを使った直接生成も指摘する" do
    expect_offense(<<~RUBY)
      RSpec.describe User do
        context "登録済み" do
          let(:user) { described_class.create }
                                       ^^^^^^ Use Factory Bot to build or create test records.
        end
      end
    RUBY
  end

  it "factoryの呼び出しや検証対象の業務メソッド、他のクラスの生成を許可する" do
    expect_no_offenses(<<~RUBY)
      RSpec.describe User do
        build(:user)
        create(:user)
        User.find_by(email: "hana@example.org")
        RegistrationInvitation.deliver_to!("hana@example.org")
        Mail::Address.new("hana@example.org")
        describe Mail::Address do
          described_class.new
        end
      end
    RUBY
  end
end
