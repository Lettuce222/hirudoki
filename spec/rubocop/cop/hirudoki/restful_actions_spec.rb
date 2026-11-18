require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../lib/rubocop/cop/hirudoki/restful_actions"

RSpec.describe RuboCop::Cop::Hirudoki::RestfulActions, :config do
  it "標準7アクション以外のpublicメソッドを検出する" do
    expect_offense(<<~RUBY)
      class PostsController < ApplicationController
        def publish
            ^^^^^^^ Public method `publish` must be a standard REST action. Extract a resource or make the helper private.
        end
      end
    RUBY
  end

  it "標準7アクションを許可する" do
    expect_no_offenses(<<~RUBY)
      class PostsController < ApplicationController
        def index; end
        def show; end
        def new; end
        def create; end
        def edit; end
        def update; end
        def destroy; end
      end
    RUBY
  end

  it "privateとprotectedのブロック・インライン・名前指定を許可する" do
    expect_no_offenses(<<~RUBY)
      class PostsController < ApplicationController
        def load_post; end
        private :load_post
        def load_category; end
        protected :load_category
        private def normalize_params; end
        protected def current_account; end

        private
        def set_post; end

        protected
        def set_account; end
      end
    RUBY
  end

  it "publicに戻した後のメソッドを検出する" do
    expect_offense(<<~RUBY)
      class PostsController < ApplicationController
        private
        def set_post; end

        public
        def publish; end
            ^^^^^^^ Public method `publish` must be a standard REST action. Extract a resource or make the helper private.
      end
    RUBY
  end

  it "名前指定でpublicに変更したメソッドを検出する" do
    expect_offense(<<~RUBY)
      class PostsController < ApplicationController
        private
        def publish; end
            ^^^^^^^ Public method `publish` must be a standard REST action. Extract a resource or make the helper private.
        public :publish
      end
    RUBY
  end

  it "インラインprivateを名前指定でpublicに変更したメソッドを検出する" do
    expect_offense(<<~RUBY)
      class PostsController < ApplicationController
        private def publish; end
                    ^^^^^^^ Public method `publish` must be a standard REST action. Extract a resource or make the helper private.
        public :publish
      end
    RUBY
  end

  it "名前空間付きcontrollerも検査する" do
    expect_offense(<<~RUBY)
      class Admin::PostsController < ApplicationController
        def publish; end
            ^^^^^^^ Public method `publish` must be a standard REST action. Extract a resource or make the helper private.
      end
    RUBY
  end

  it "クラスメソッドとcontroller以外の内部クラスは検査しない" do
    expect_no_offenses(<<~RUBY)
      class PostsController < ApplicationController
        def self.configure; end

        class << self
          def configure; end
        end

        class Result
          def success?; end
        end
      end
    RUBY
  end

  it "controller以外のクラスやConcernのmoduleは検査しない" do
    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        def publish; end
      end

      module Publishable
        def publish; end
      end
    RUBY
  end

  it "Rubyが暗黙にprivateにするinitializeを許可する" do
    expect_no_offenses(<<~RUBY)
      class PostsController < ApplicationController
        def initialize; end
      end
    RUBY
  end
end
