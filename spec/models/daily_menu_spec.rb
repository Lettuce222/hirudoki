require "rails_helper"

RSpec.describe DailyMenu, type: :model do
  let(:date) { Date.new(2026, 11, 24) }
  let(:salmon) { Bento.create!(name: "鮭弁当", category: "和食", price: 650, display_order: 1) }
  let(:saba) { Bento.create!(name: "さば弁当", category: "和食", price: 600, display_order: 2) }
  let(:pasta) { Bento.create!(name: "パスタ弁当", category: "洋食", price: 720, display_order: 3) }
  let(:attributes) { { served_on: date, bento: salmon, capacity: 10 } }

  it "日付、弁当、0以上の整数の提供数上限を指定する" do
    expect(described_class.new(attributes.merge(capacity: 0))).to be_valid
    expect(described_class.new(attributes.merge(capacity: -1))).not_to be_valid
    expect(described_class.new(attributes.merge(capacity: 1.5))).not_to be_valid
    expect(described_class.new(attributes.merge(served_on: nil))).not_to be_valid
    expect(described_class.new(attributes.merge(bento: nil))).not_to be_valid
  end

  it "日付が同じなら弁当もタイプも重複せず、別の日には再び登録できる" do
    described_class.create!(attributes)
    expect(described_class.new(attributes)).not_to be_valid
    expect(described_class.new(attributes.merge(bento: saba))).not_to be_valid
    expect(described_class.new(attributes.merge(bento: pasta))).to be_valid
    expect(described_class.new(attributes.merge(served_on: date.tomorrow))).to be_valid
  end

  it "弁当のタイプ変更を献立へ反映し、同日にタイプが重なる変更を拒む" do
    menu = described_class.create!(attributes)
    described_class.create!(attributes.merge(bento: pasta))
    expect(salmon.update(category: "洋食")).to be(false)
    salmon.update!(category: "中華")
    expect(menu.reload.category).to eq("中華")
    expect(described_class.new(attributes.merge(bento: saba))).to be_valid
  end

  it "献立の同日同タイプ重複をDBでも拒む" do
    described_class.create!(attributes)
    expect {
      described_class.transaction(requires_new: true) do
        described_class.insert_all!([ { served_on: date, bento_id: saba.id, category: "和食", capacity: 1 } ])
      end
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "献立が参照している弁当は削除できず、非販売には変更できる" do
    described_class.create!(attributes)
    expect(salmon.destroy).to be(false)
    expect(salmon.update(on_sale: false)).to be(true)
  end
end
