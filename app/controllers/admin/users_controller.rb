class Admin::UsersController < Admin::BaseController
  def index
    @users = User.asc_by_name
  end

  def show
    @user = User.find(params[:id])
    @month = params[:month].present? ? Date.iso8601("#{params[:month]}-01") : Date.current.beginning_of_month
    @monthly_bill = @user.monthly_bill(@month)
  rescue Date::Error
    flash.now[:alert] = "有効な請求月を指定してください。"
    render :show, status: :unprocessable_content
  end
end
