class DailyMenusController < ApplicationController
  before_action :require_user

  def index
    @filters = catalog_params
    @menus = DailyMenu.on_sale
                      .filtered_by(served_on: @filters[:served_on], bento_type: @filters[:bento_type])
                      .in_display_order
                      .preload(bento: { image_attachment: :blob })
  end

  def show
    @filters = catalog_params
    @menu = DailyMenu.on_sale.find(params[:id])
  end

  private

  def catalog_params
    params.permit(:served_on, :bento_type)
  end

  def require_user
    redirect_to root_path unless user_signed_in?
  end
end
