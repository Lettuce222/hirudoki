require "rails_helper"

RSpec.describe Review, type: :model do
  let(:served_on) { Date.new(2028, 2, 29) }
  let(:menu) { create(:daily_menu, served_on:) }
  let(:order) do
    travel_to(Time.zone.local(2028, 2, 28, 9)) { create(:order, daily_menu: menu) }
  end

  it "受取済みの注文に1回だけ評価とコメントを投稿できる" do
    order.received!
    review = order.create_review!(rating: 5, comment: "おいしかったです。")

    expect(review.reload).to have_attributes(rating: 5, comment: "おいしかったです。")
    expect(described_class.create(order:, rating: 4)).not_to be_persisted
    expect do
      described_class.insert_all!([ { order_id: order.id, rating: 4 } ])
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "注文済みとキャンセル済みの注文には評価を投稿できない" do
    %i[ordered cancelled].each do |status|
      order.update!(status:)
      expect(described_class.create(order:, rating: 5)).not_to be_persisted
    end
  end

  it "表示後に注文がキャンセルされた場合は古い注文状態で投稿できない" do
    order.received!
    stale_order = Order.find(order.id)
    order.cancelled!

    expect(described_class.create(order: stale_order, rating: 5)).not_to be_persisted
  end

  it "評価は1から5の整数に限る" do
    order.received!
    [ 0, 6, "3.5", nil ].each do |rating|
      expect(described_class.new(order:, rating:)).not_to be_valid
    end
    expect(described_class.new(order:, rating: 1)).to be_valid
    expect do
      described_class.insert_all!([ { order_id: order.id, rating: 6 } ])
    end.to raise_error(ActiveRecord::StatementInvalid, /reviews_rating_range/)
  end
end
