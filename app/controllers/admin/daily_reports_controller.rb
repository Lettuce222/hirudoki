class Admin::DailyReportsController < Admin::BaseController
  def show
    @served_on = params[:served_on].present? ? Date.iso8601(params[:served_on].to_s) : Date.current
    @production_quantities = Order.production_quantities(@served_on)
    @deliveries = Order.for_delivery(@served_on)
  rescue Date::Error
    flash.now[:alert] = "有効な提供日を指定してください。"
    render :show, status: :unprocessable_content
  end
end
