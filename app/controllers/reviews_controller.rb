class ReviewsController < ApplicationController
  before_action :no_store
  before_action :require_user
  before_action :set_order, :set_menu, :set_reviews

  def new
    return redirect_to @order, alert: "この注文は評価できません。", status: :see_other unless @order.reviewable?

    @review = Review.new
  end

  def create
    @review = Review.new(review_params.merge(order_id: @order.id))
    if @review.save
      redirect_to @order, notice: "評価を投稿しました。", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def review_params
    params.expect(review: [ :rating, :comment ])
  end

  def set_order
    @order = current_user.orders.find(params.expect(:order_id))
  end

  def set_menu
    @menu = @order.daily_menu
  end

  def set_reviews
    @reviews = @menu.reviews.desc_by_created_at
  end
end
