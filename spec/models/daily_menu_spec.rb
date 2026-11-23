require "rails_helper"

RSpec.describe DailyMenu, type: :model do
  let(:date) { Date.new(2026, 11, 24) }
  let(:salmon) { Bento.create!(name: "鮭弁当", bento_type: "和食", price: 650, display_order: 1) }
  let(:saba) { Bento.create!(name: "さば弁当", bento_type: "和食", price: 600, display_order: 2) }
  let(:pasta) { Bento.create!(name: "パスタ弁当", bento_type: "洋食", price: 720, display_order: 3) }

  def build_menu(**attributes)
    described_class.new(served_on: date, bento: salmon, capacity: 10, **attributes)
  end

  it "日付、弁当、0以上の整数の提供数上限を指定する" do
    expect(build_menu(capacity: 0)).to be_valid
    expect(build_menu(capacity: -1)).not_to be_valid
    expect(build_menu(capacity: 1.5)).not_to be_valid
    expect(build_menu(served_on: nil)).not_to be_valid
    expect(build_menu(bento: nil)).not_to be_valid
  end

  it "日付が同じなら弁当もタイプも重複せず、別の日には再び登録できる" do
    build_menu.save!
    expect(build_menu).not_to be_valid
    expect(build_menu(bento: saba)).not_to be_valid
    expect(build_menu(bento: pasta)).to be_valid
    expect(build_menu(served_on: date.tomorrow)).to be_valid
  end

  it "弁当のタイプ変更を献立へ反映し、同日にタイプが重なる変更を拒む" do
    menu = build_menu
    menu.save!
    build_menu(bento: pasta).save!
    expect(salmon.update(bento_type: "洋食")).to be(false)
    salmon.update!(bento_type: "中華")
    expect(menu.reload.bento.bento_type).to eq("中華")
    expect(described_class.column_names).not_to include("category", "bento_type")
    expect(build_menu(bento: saba)).to be_valid
  end

  it "弁当を読み込んだ後にタイプが変更された場合も現在のタイプで検証する" do
    menu = build_menu(bento: pasta)
    Bento.find(pasta.id).update!(bento_type: "和食")
    build_menu.save!
    expect(menu.save).to be(false)
    expect(menu.errors[:bento]).to be_present
  end

  it "先に別の弁当に差し替えられた献立を古い画面から移動しても重複を作らない" do
    menu = build_menu
    menu.save!
    previous = described_class.find(menu.id)
    menu.update!(bento: pasta)
    another_pasta = Bento.create!(name: "野菜パスタ弁当", bento_type: "洋食", price: 580, display_order: 4)
    build_menu(bento: another_pasta, served_on: date.tomorrow).save!
    expect(previous.update(served_on: date.tomorrow)).to be(false)
    expect(menu.reload.served_on).to eq(date)
  end

  it "モデルを通さない書き込みでも負の提供数を保存できない" do
    expect {
      described_class.transaction(requires_new: true) do
        described_class.insert_all!([ { served_on: date, bento_id: salmon.id, capacity: -1 } ])
      end
    }.to raise_error(ActiveRecord::StatementInvalid) { |error| expect(error.cause).to be_a(PG::CheckViolation) }
  end

  it "同じ提供日と弁当IDの重複をDBでも拒む" do
    build_menu.save!
    expect {
      described_class.transaction(requires_new: true) do
        described_class.insert_all!([ { served_on: date, bento_id: salmon.id, capacity: 1 } ])
      end
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "献立が参照している弁当は削除できず、非販売には変更できる" do
    build_menu.save!
    expect(salmon.destroy).to be(false)
    expect(salmon.update(on_sale: false)).to be(true)
  end
end
