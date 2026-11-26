class OrdersController < ApplicationController
  before_action :no_store
  before_action :require_user
  before_action :load_menu, only: %i[new create]
  before_action :set_order, only: %i[show edit update]

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

  def show; end

  def edit
    unless @order.changeable?
      redirect_to @order, alert: "この注文は変更できません。", status: :see_other
    end
  end

  def update
    attributes = update_params
    return cancel_order if attributes[:intent] == "cancel"

    if @order.change_quantity(attributes[:quantity])
      redirect_to @order, notice: "個数を変更しました。", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def cancel_order
    if @order.cancel
      redirect_to @order, notice: "注文をキャンセルしました。", status: :see_other
    else
      redirect_to @order, alert: @order.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def update_params
    params.expect(order: [ :quantity, :intent ])
  end

  def set_order
    @order = current_user.orders.find(params.expect(:id))
  end

  def order_params
    params.expect(order: [ :quantity, :delivery_address, :delivery_area_id ])
  end

  def load_menu
    @menu = DailyMenu.on_sale.find(params[:daily_menu_id])
    @areas = DeliveryArea.active.asc_by_postal_code
  end
end
