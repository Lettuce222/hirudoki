class DailyMenusController < ApplicationController
  before_action :require_user

  def index
    @filters = filter_params
    @menus = DailyMenu.on_sale
                      .filtered_by(served_on: @filters[:served_on], bento_type: @filters[:bento_type])
                      .in_display_order
                      .preload(bento: { image_attachment: :blob })
    @ordered_by_menu = Order.not_cancelled.where(daily_menu_id: @menus.map(&:id)).group(:daily_menu_id).sum(:quantity)
  end

  def show
    @filters = filter_params
    @menu = DailyMenu.on_sale.find(params[:id])
  end

  private

  def filter_params
    params.permit(:served_on, :bento_type)
  end
end
