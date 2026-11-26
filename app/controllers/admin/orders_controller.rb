class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: %i[show update]

  def index
    @orders = Order.desc_by_created_at.preload(:user, daily_menu: :bento)
  end

  def show; end

  def update
    if @order.change_status(order_params[:status])
      redirect_to admin_order_path(@order), notice: "注文状態を保存しました。", status: :see_other
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_order
    @order = Order.find(params.expect(:id))
  end

  def order_params
    params.expect(order: [ :status ])
  end
end
