require "rails_helper"

RSpec.describe ReviewsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:order) do
    travel_to(Time.zone.local(2028, 2, 29, 9)) do
      create(:order, daily_menu: create(:daily_menu, served_on: Date.new(2028, 2, 29)))
    end
  end
  let(:attributes) { { rating: 5, comment: "おいしかったです。" } }

  context "未ログインの場合" do
    it "評価フォームを開けず、投稿もできない" do
      get new_order_review_path(order)
      expect(response).to redirect_to(root_path)

      expect { post order_review_path(order), params: { review: attributes } }.not_to change(Review, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  context "ログイン済みの場合" do
    before { sign_in order.user }

    it "受取済みの注文を評価すると注文詳細に戻る" do
      order.received!

      get new_order_review_path(order)
      expect(response).to have_http_status(:ok)

      post order_review_path(order), params: { review: attributes }
      expect(response).to redirect_to(order_path(order))
      expect(order.reload.review).to have_attributes(attributes)
    end

    it "受取済みになるまで評価フォームを開けず、投稿もできない" do
      get new_order_review_path(order)
      expect(response).to redirect_to(order_path(order))

      expect { post order_review_path(order), params: { review: attributes } }.not_to change(Review, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "2回目の投稿を拒否し、先に投稿された評価を保持する" do
      order.received!
      order.create_review!(rating: 4)

      expect { post order_review_path(order), params: { review: attributes } }.not_to change(Review, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("注文は評価済みです。")
      expect(order.reload.review.rating).to eq(4)
    end

    it "評価の範囲外では入力内容とエラーを表示する" do
      order.received!

      expect do
        post order_review_path(order), params: { review: attributes.merge(rating: 6) }
      end.not_to change(Review, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("評価は1〜5の整数で入力してください。", attributes.fetch(:comment))
    end

    it "別の利用者の注文には評価を投稿できない" do
      other_order = travel_to(Time.zone.local(2028, 2, 29, 9)) { create(:order, daily_menu: order.daily_menu) }
      other_order.received!

      expect { post order_review_path(other_order), params: { review: attributes } }.not_to change(Review, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
