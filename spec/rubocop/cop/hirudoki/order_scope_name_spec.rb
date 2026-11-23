require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../lib/rubocop/cop/hirudoki/order_scope_name"

RSpec.describe RuboCop::Cop::Hirudoki::OrderScopeName, :config do
  it "並べ替えだけのscopeには最初の列と昇順・降順を明記する" do
    expect_offense(<<~RUBY)
      scope :by_postal_code, -> { order(:postal_code, :id) }
            ^^^^^^^^^^^^^^^ Name this scope postal_code_asc.
      scope :served_on_asc, -> { order(served_on: :desc, id: :asc) }
            ^^^^^^^^^^^^^^ Name this scope served_on_desc.
    RUBY
  end

  it "列と方向が一致する名前を許可し、絞り込みや複数モデルを使う業務上の表示順は対象外とする" do
    expect_no_offenses(<<~RUBY)
      scope :postal_code_asc, -> { order(:postal_code, :id) }
      scope :served_on_desc, -> { order(served_on: :desc, id: :asc) }
      scope :by_postal_code, ->(code) { where(postal_code: code) }
      scope :in_display_order, -> { joins(:bento).order(:served_on, "bentos.display_order", :id) }
    RUBY
  end
end
