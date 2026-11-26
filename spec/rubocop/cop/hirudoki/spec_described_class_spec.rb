require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../lib/rubocop/cop/hirudoki/spec_described_class"

RSpec.describe RuboCop::Cop::Hirudoki::SpecDescribedClass, :config do
  it "モデルのファイル名と異なるクラスを拒否する" do
    expect_offense(<<~RUBY, "spec/models/order_spec.rb")
      RSpec.describe Review do
                     ^^^^^^ Describe the class or module corresponding to this spec file.
      end
    RUBY
  end

  it "クラス名の代わりに文字列で例のグループを宣言すると拒否する" do
    expect_offense(<<~RUBY, "spec/models/order_spec.rb")
      RSpec.describe "Order" do
                     ^^^^^^^ Describe the class or module corresponding to this spec file.
      end
    RUBY
  end

  it "リクエスト spec ではコントローラーの名前空間も照合する" do
    expect_offense(<<~RUBY, "spec/requests/admin/sessions_spec.rb")
      RSpec.describe SessionsController do
                     ^^^^^^^^^^^^^^^^^^ Describe the class or module corresponding to this spec file.
      end
    RUBY

    expect_no_offenses(<<~RUBY, "spec/requests/admin/sessions_spec.rb")
      RSpec.describe Admin::SessionsController do
        describe "#destroy" do
        end
      end
    RUBY
  end

  it "Rails の concern はモデルのロードパスに従う" do
    expect_no_offenses(<<~RUBY, "spec/models/concerns/password_authentication_spec.rb")
      RSpec.describe PasswordAuthentication do
      end
    RUBY
  end
end
