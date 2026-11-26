class OrderCancellationsController < ApplicationController
  before_action :no_store
  before_action :require_user
  before_action :set_order

  def create
    if @order.cancel
      redirect_to @order, notice: "注文をキャンセルしました。", status: :see_other
    else
      redirect_to @order, alert: @order.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_order
    @order = current_user.orders.find(params.expect(:order_id))
  end
end
