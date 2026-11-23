require "rails_helper"

RSpec.describe Bento, type: :model do
  it "4種類からタイプを選び、0円の弁当も販売中で登録できる" do
    %w[和食 洋食 中華 ヘルシー].each do |bento_type|
      bento = create(:bento, bento_type:, price: 0)
      expect(bento).to be_on_sale
    end
  end

  it "名前・タイプ・税抜価格・表示順が必要で、未定義のタイプや負の価格を拒む" do
    expect(build(:bento, name: "")).not_to be_valid
    expect(build(:bento, bento_type: "その他")).not_to be_valid
    expect(build(:bento, price: -1)).not_to be_valid
    expect(build(:bento, display_order: nil)).not_to be_valid
  end
end
