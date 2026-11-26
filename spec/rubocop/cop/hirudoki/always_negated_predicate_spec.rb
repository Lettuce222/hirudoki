require "rubocop"
require "rubocop/rspec/support"
require "tmpdir"
require_relative "../../../../lib/rubocop/cop/hirudoki/always_negated_predicate"

RSpec.describe RuboCop::Cop::Hirudoki::AlwaysNegatedPredicate, :config do
  def with_sources(**sources)
    Dir.mktmpdir do |directory|
      paths = sources.map do |name, content|
        File.join(directory, name.to_s).tap { |path| File.write(path, content) }
      end
      allow(cop).to receive(:source_paths).and_return(paths)
      yield
    end
  end

  it "別ファイルからの呼び出しもすべて否定される述語を検出する" do
    with_sources("daily_menu.rb": "def order_cutoff_passed?; false; end",
      "order.rb": "!daily_menu.order_cutoff_passed?; not(daily_menu.order_cutoff_passed?)") do
      expect_offense(<<~RUBY)
        def order_cutoff_passed?
            ^^^^^^^^^^^^^^^^^^^^ Every direct call to this predicate is negated. Give the inverse a positive name.
          false
        end
      RUBY
    end
  end

  it "別ファイルで肯定形の呼び出しがあれば許容する" do
    with_sources("daily_menu.rb": "def order_cutoff_passed?; false; end",
      "order.rb": "!daily_menu.order_cutoff_passed?; daily_menu.order_cutoff_passed?") do
      expect_no_offenses("def order_cutoff_passed?; false; end")
    end
  end

  it "同名の定義や間接的な参照がある場合は判定しない" do
    with_sources("menus.rb": <<~RUBY, "orders.rb": <<~ORDERS) do
      def closed?; false; end
      def self.closed?; false; end
      def late?; false; end
    RUBY
      !menu.closed?
      !menu.late?
      menus.select(&:late?)
    ORDERS
      expect_no_offenses("def closed?; false; end; def late?; false; end")
    end
  end

  it "二重否定や安全ナビゲーションを逆の述語への置き換え候補にしない" do
    with_sources("daily_menu.rb": "def closed?; false; end; def late?; false; end",
      "order.rb": "!!menu.closed?; !menu&.late?") do
      expect_no_offenses("def closed?; false; end; def late?; false; end")
    end
  end

  it "テンプレートに参照がある場合は判定しない" do
    with_sources("daily_menu.rb": "def order_cutoff_passed?; false; end",
      "order.rb": "!daily_menu.order_cutoff_passed?",
      "show.html.erb": "<%= @daily_menu.order_cutoff_passed? %>") do
      expect_no_offenses("def order_cutoff_passed?; false; end")
    end
  end
end
