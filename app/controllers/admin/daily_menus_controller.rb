class Admin::DailyMenusController < Admin::BaseController
  before_action :set_daily_menu, only: %i[edit update destroy]
  before_action :set_bentos, only: %i[new create edit update]

  def index
    @daily_menus = paginate(DailyMenu.includes(:bento).desc_by_served_on)
  end

  def new
    @daily_menu = DailyMenu.new(served_on: Date.current)
    render :form
  end

  def create
    @daily_menu = DailyMenu.new(daily_menu_params)
    if @daily_menu.save
      redirect_to admin_daily_menus_path, notice: "保存しました。", status: :see_other
    else
      render :form, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    @daily_menu.errors.add(:bento, "は同じ提供日にすでに登録されています")
    render :form, status: :unprocessable_content
  rescue ActiveRecord::InvalidForeignKey
    @daily_menu.errors.add(:bento, "を選び直してください")
    render :form, status: :unprocessable_content
  end

  def edit
    render :form
  end

  def update
    if @daily_menu.update(daily_menu_params)
      redirect_to admin_daily_menus_path, notice: "保存しました。", status: :see_other
    else
      render :form, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    @daily_menu.errors.add(:bento, "は同じ提供日にすでに登録されています")
    render :form, status: :unprocessable_content
  rescue ActiveRecord::InvalidForeignKey
    @daily_menu.errors.add(:bento, "を選び直してください")
    render :form, status: :unprocessable_content
  end

  def destroy
    if @daily_menu.destroy
      redirect_to admin_daily_menus_path, notice: "削除しました。", status: :see_other
    else
      alert = @daily_menu.errors[:base].first || "日別献立を削除できませんでした。"
      redirect_to admin_daily_menus_path, alert:, status: :see_other
    end
  rescue ActiveRecord::InvalidForeignKey
    redirect_to admin_daily_menus_path, alert: "日別献立を削除できませんでした。注文履歴を確認してください。", status: :see_other
  end

  private

  def set_daily_menu
    @daily_menu = DailyMenu.find(params[:id])
  end

  def set_bentos
    @bentos = Bento.asc_by_display_order.to_a
  end

  def daily_menu_params
    params.expect(daily_menu: [ :served_on, :bento_id, :capacity ])
  end
end
