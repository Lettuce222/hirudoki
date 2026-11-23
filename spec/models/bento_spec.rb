require "rails_helper"

RSpec.describe Bento, type: :model do
  let(:attributes) { { name: "鮭弁当", category: "和食", price: 650, display_order: 1 } }

  it "4種類からタイプを選び、0円の弁当も販売中で登録できる" do
    %w[和食 洋食 中華 ヘルシー].each do |category|
      bento = described_class.create!(attributes.merge(category: category, price: 0))
      expect(bento).to be_on_sale
    end
  end

  it "名前・タイプ・税抜価格・表示順が必要で、未定義のタイプや負の価格を拒む" do
    expect(described_class.new).not_to be_valid
    expect(described_class.new(attributes.merge(category: "その他"))).not_to be_valid
    expect(described_class.new(attributes.merge(price: -1))).not_to be_valid
    expect(described_class.new(attributes.merge(display_order: nil))).not_to be_valid
  end
end
