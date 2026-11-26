class RecurringOrderSettingsController < ApplicationController
  before_action :no_store
  before_action :require_user
  before_action :load_setting, only: %i[edit update]

  def index
    @settings = current_user.recurring_order_settings.asc_by_weekday.preload(:delivery_area)
  end

  def new
    @setting = current_user.recurring_order_settings.build(quantity: 1, active: true)
    show_form
  end

  def create
    @setting = current_user.recurring_order_settings.build(recurring_order_setting_params)
    save_setting
  end

  def edit
    show_form
  end

  def update
    @setting.assign_attributes(recurring_order_setting_params)
    save_setting
  end

  private

  def load_setting
    @setting = current_user.recurring_order_settings.find(params.expect(:id))
  end

  def recurring_order_setting_params
    params.expect(recurring_order_setting: [ :weekday, :bento_type, :quantity, :delivery_area_id, :delivery_address, :active ])
  end

  def save_setting
    if @setting.save
      redirect_to recurring_order_settings_path, notice: "定期注文設定を保存しました。", status: :see_other
    else
      show_form(status: :unprocessable_content)
    end
  rescue ActiveRecord::RecordNotUnique
    @setting.errors.add(:weekday, :taken)
    show_form(status: :unprocessable_content)
  rescue ActiveRecord::InvalidForeignKey
    @setting.errors.add(:delivery_area, "を選び直してください。")
    show_form(status: :unprocessable_content)
  end

  def show_form(status: :ok)
    @areas = DeliveryArea.active.or(DeliveryArea.where(id: @setting.delivery_area_id_in_database)).asc_by_postal_code
    render :form, status:
  end
end
