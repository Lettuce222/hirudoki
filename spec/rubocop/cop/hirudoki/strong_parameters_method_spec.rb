require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../lib/rubocop/cop/hirudoki/strong_parameters_method"

RSpec.describe RuboCop::Cop::Hirudoki::StrongParametersMethod, :config do
  it "アクション内の属性宣言を検出する" do
    expect_offense(<<~RUBY)
      def create
        params.expect(user: [:name])
               ^^^^^^ Declare permitted attributes in a private *_params method.
      end
    RUBY
  end

  it "公開されたヘルパーや命名が異なるヘルパーの属性宣言を検出する" do
    expect_offense(<<~RUBY)
      class UsersController
        def user_params
          params.require(:user).permit(:name)
                                ^^^^^^ Declare permitted attributes in a private *_params method.
        end

        private

        def attributes
          params.permit(:name)
                 ^^^^^^ Declare permitted attributes in a private *_params method.
        end
      end
    RUBY
  end

  it "非公開の属性宣言とアクション内の単一値の取得を許可する" do
    expect_no_offenses(<<~RUBY)
      class UsersController
        def update
          params[:token]
          params.expect(:id)
          policy.permit(:update)
        end

        private def user_params
          params.expect(user: [:name])
        end
      end
    RUBY
  end
end
