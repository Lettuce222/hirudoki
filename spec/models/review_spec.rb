require "rails_helper"
require_relative "../support/concurrent_writes"

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
    duplicate = described_class.create(order:, rating: 4)
    expect(duplicate).not_to be_persisted
    expect(duplicate.errors.full_messages).to include("注文は評価済みです。")
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

  context "別の接続から同時に投稿する場合" do
    include ConcurrentWrites
    self.use_transactional_tests = false

    after do
      described_class.where(order:).delete_all
      order.reload.destroy!
      [ order.user, order.delivery_area, menu, menu.bento ].each(&:destroy!)
    end

    it "同時投稿を評価済みとして扱い、先に投稿された評価を保持する" do
      order.received!
      order_id = order.id

      duplicate, review_count = race(-> { order.create_review!(rating: 5) }) do
        described_class.transaction do
          review = described_class.create(order_id:, rating: 3)
          [ review, described_class.where(order_id:).count ]
        end
      end

      expect(duplicate).not_to be_persisted
      expect(duplicate.errors.of_kind?(:order_id, :taken)).to be(true)
      expect(duplicate.errors.full_messages).to include("注文は評価済みです。")
      expect(review_count).to eq(1)
      expect(order.reload.review.rating).to eq(5)
    end
  end
end
