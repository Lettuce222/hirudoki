require "rails_helper"
require_relative "../support/concurrent_writes"

RSpec.describe DailyMenu, type: :model do
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:salmon) { create(:bento, name: "鮭弁当", bento_type: "和食") }
  let(:saba) { create(:bento, name: "さば弁当", bento_type: "和食") }
  let(:pasta) { create(:bento, name: "パスタ弁当", bento_type: "洋食") }

  it "販売中の献立を指定された提供日・弁当タイプだけで絞り込める" do
    salmon_menu = create(:daily_menu, served_on:, bento: salmon)
    next_day_menu = create(:daily_menu, served_on: served_on.tomorrow, bento: salmon)
    western = create(:daily_menu, served_on:, bento: pasta)
    saba.update!(on_sale: false)
    create(:daily_menu, served_on: served_on.yesterday, bento: saba)

    menus = described_class.on_sale
    expect(menus.filtered_by(served_on: "", bento_type: "")).to contain_exactly(salmon_menu, next_day_menu, western)
    expect(menus.filtered_by(served_on:)).to contain_exactly(salmon_menu, western)
    expect(menus.filtered_by(bento_type: "和食")).to contain_exactly(salmon_menu, next_day_menu)
  end

  it "日付、弁当、0以上の整数の提供数上限を指定する" do
    expect(build(:daily_menu, capacity: 0)).to be_valid
    expect(build(:daily_menu, capacity: -1)).not_to be_valid
    expect(build(:daily_menu, capacity: 1.5)).not_to be_valid
    expect(build(:daily_menu, served_on: nil)).not_to be_valid
    expect(build(:daily_menu, bento: nil)).not_to be_valid
  end

  it "日付が同じなら弁当もタイプも重複せず、別の日には再び登録できる" do
    create(:daily_menu, served_on:, bento: salmon)
    expect(build(:daily_menu, served_on:, bento: salmon)).not_to be_valid
    expect(build(:daily_menu, served_on:, bento: saba)).not_to be_valid
    expect(build(:daily_menu, served_on:, bento: pasta)).to be_valid
    expect(build(:daily_menu, served_on: served_on.tomorrow, bento: salmon)).to be_valid
  end

  it "弁当のタイプ変更を献立へ反映し、同日にタイプが重なる変更を拒む" do
    menu = create(:daily_menu, served_on:, bento: salmon)
    create(:daily_menu, served_on:, bento: pasta)
    expect(salmon.update(bento_type: "洋食")).to be(false)
    salmon.update!(bento_type: "中華")
    expect(menu.reload.bento.bento_type).to eq("中華")
    expect(described_class.column_names).not_to include("category", "bento_type")
    expect(build(:daily_menu, served_on:, bento: saba)).to be_valid
  end

  it "弁当を読み込んだ後にタイプが変更された場合も現在のタイプで検証する" do
    menu = build(:daily_menu, served_on:, bento: pasta)
    Bento.find(pasta.id).update!(bento_type: "和食")
    create(:daily_menu, served_on:, bento: salmon)
    expect(menu.save).to be(false)
    expect(menu.errors[:bento]).to be_present
  end

  it "先に別の弁当に差し替えられた献立を古い画面から移動しても重複を作らない" do
    menu = create(:daily_menu, served_on:, bento: salmon)
    previous = described_class.find(menu.id)
    menu.update!(bento: pasta)
    another_pasta = create(:bento, bento_type: "洋食")
    create(:daily_menu, bento: another_pasta, served_on: served_on.tomorrow)
    expect(previous.update(served_on: served_on.tomorrow)).to be(false)
    expect(menu.reload.served_on).to eq(served_on)
  end

  it "献立が参照している弁当は削除できず、非販売には変更できる" do
    create(:daily_menu, served_on:, bento: salmon)
    expect(salmon.destroy).to be(false)
    expect(salmon.update(on_sale: false)).to be(true)
  end

  context "献立を同時に更新する場合" do
    include ConcurrentWrites
    self.use_transactional_tests = false

    let(:served_on) { Date.new(2026, 12, 3) }
    let!(:first_bento) { create(:bento, bento_type: "和食") }
    let!(:second_bento) { create(:bento, bento_type: "和食") }

    after do
      ids = [ first_bento.id, second_bento.id ]
      DailyMenu.where(bento_id: ids).delete_all
      Bento.where(id: ids).delete_all
    end

    it "別の弁当でも、同じ日・同じタイプの同時登録は片方だけ保存する" do
      accepted = race(-> { create(:daily_menu, served_on:, bento: first_bento) }) do
        build(:daily_menu, served_on:, bento: second_bento).save
      end
      expect(accepted).to be(false)
      expect(DailyMenu.where(served_on:, bento_id: [ first_bento.id, second_bento.id ]).count).to eq(1)
    end

    it "献立の登録中に、同日の別の弁当を同じタイプに変更できない" do
      second_bento.update!(bento_type: "洋食")
      create(:daily_menu, served_on:, bento: second_bento)
      accepted = race(-> { create(:daily_menu, served_on:, bento: first_bento) }) do
        second_bento.update(bento_type: "和食")
      end
      expect(accepted).to be(false)
      expect(second_bento.reload.bento_type).to eq("洋食")
    end

    it "弁当タイプの変更中に、その変更と重複する献立を保存できない" do
      second_bento.update!(bento_type: "洋食")
      create(:daily_menu, served_on:, bento: second_bento)
      accepted = race(-> { second_bento.update!(bento_type: "和食") }) do
        build(:daily_menu, served_on:, bento: first_bento).save
      end
      expect(accepted).to be(false)
      expect(DailyMenu.exists?(served_on:, bento: first_bento)).to be(false)
    end
  end
end
