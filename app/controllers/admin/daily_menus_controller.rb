class Admin::DailyMenusController < Admin::BaseController
  before_action :set_daily_menu, only: %i[edit update destroy]
  before_action :load_bentos, only: %i[new create edit update]

  def index
    @daily_menus = paginate(DailyMenu.includes(:bento).desc_by_served_on)
  end

  def new
    @daily_menu = DailyMenu.new(served_on: Date.current)
    render :form
  end

  def create
    @daily_menu = DailyMenu.new(daily_menu_params)
    save_record(@daily_menu, admin_daily_menus_path)
  end

  def edit
    render :form
  end

  def update
    @daily_menu.assign_attributes(daily_menu_params)
    save_record(@daily_menu, admin_daily_menus_path)
  end

  def destroy
    destroy_record(@daily_menu, admin_daily_menus_path)
  end

  private

  def set_daily_menu
    @daily_menu = DailyMenu.find(params[:id])
  end

  def load_bentos
    @bentos = Bento.asc_by_display_order.to_a
  end

  def daily_menu_params
    params.expect(daily_menu: [ :served_on, :bento_id, :capacity ])
  end
end
