require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../lib/rubocop/cop/hirudoki/controller_setters"

RSpec.describe RuboCop::Cop::Hirudoki::ControllerSetters, :config do
  it "名前に対応する変数に検索結果を代入するメソッドを許可する" do
    expect_no_offenses(<<~RUBY)
      class OrdersController
        before_action :set_order
        before_action :require_user

        def show
          @title = "注文"
        end

        private

        def set_order
          @order = current_user.orders.find(params.expect(:id))
        end

        def require_user
          redirect_to root_path unless current_user
        end
      end
    RUBY
  end

  it "コールバックの名前がset_で始まらない場合を検出する" do
    expect_offense(<<~RUBY)
      class OrdersController
        before_action :load_order

        def load_order
            ^^^^^^^^^^ Assign one matching instance variable in a set_* method using only read operations.
          @order = Order.find(params[:id])
        end
      end
    RUBY
  end

  it "インスタンス変数を直接代入するコールバックのブロックを検出する" do
    expect_offense(<<~RUBY)
      class OrdersController
        before_action { @order = Order.find(params[:id]) }
        ^^^^^^^^^^^^^ Assign one matching instance variable in a set_* method using only read operations.
      end
    RUBY
  end

  it "名前と変数の不一致や複数の代入を検出する" do
    expect_offense(<<~RUBY)
      def set_order
          ^^^^^^^^^ Assign one matching instance variable in a set_* method using only read operations.
        @item = Order.find(params[:id])
      end

      def set_areas
          ^^^^^^^^^ Assign one matching instance variable in a set_* method using only read operations.
        @areas = DeliveryArea.active
        @orders = current_user.orders
      end
    RUBY
  end

  it "代入の前後の処理と代入する式の中の書き込みを検出する" do
    expect_offense(<<~RUBY)
      def set_order
          ^^^^^^^^^ Assign one matching instance variable in a set_* method using only read operations.
        @order = Order.find(params[:id])
        @order.save
      end

      def set_orders
          ^^^^^^^^^^ Assign one matching instance variable in a set_* method using only read operations.
        @orders = current_user.orders.where(id: Report.generate)
      end
    RUBY
  end
end
