class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: %i[show update]

  def index
    @orders = Order.for_administration
  end

  def show; end

  def update
    if @order.change_status_by_administrator(order_params[:status])
      redirect_to admin_order_path(@order), notice: "注文状態を保存しました。", status: :see_other
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_order
    @order = Order.for_administration.find(params[:id])
  end

  def order_params
    params.expect(order: [ :status ])
  end
end
