class OrdersController < ApplicationController
  before_action :no_store
  before_action :require_user
  before_action :load_menu

  def new
    previous = current_user.orders.desc_by_created_at.first
    @order = current_user.orders.build(quantity: 1, delivery_address: previous&.delivery_address,
      delivery_area_id: previous&.delivery_area_id)
  end

  def create
    @order = current_user.orders.build(order_params.merge(daily_menu: @menu))
    if @order.confirm
      redirect_to profile_path, notice: "注文を受け付けました。", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def order_params
    params.expect(order: [ :quantity, :delivery_address, :delivery_area_id ])
  end

  def load_menu
    @menu = DailyMenu.on_sale.find(params[:daily_menu_id])
    @areas = DeliveryArea.where(active: true).asc_by_postal_code
  end
end
