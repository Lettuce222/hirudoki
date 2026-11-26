class Admin::DeliveryAreasController < Admin::BaseController
  before_action :set_delivery_area, only: %i[edit update destroy]

  def index
    @delivery_areas = DeliveryArea.asc_by_postal_code
  end

  def new
    @delivery_area = DeliveryArea.new
    render :form
  end

  def create
    @delivery_area = DeliveryArea.new(delivery_area_params)
    if @delivery_area.save
      redirect_to admin_delivery_areas_path, notice: "保存しました。", status: :see_other
    else
      render :form, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    @delivery_area.errors.add(:postal_code, :taken)
    render :form, status: :unprocessable_content
  end

  def edit
    render :form
  end

  def update
    if @delivery_area.update(delivery_area_params)
      redirect_to admin_delivery_areas_path, notice: "保存しました。", status: :see_other
    else
      render :form, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    @delivery_area.errors.add(:postal_code, :taken)
    render :form, status: :unprocessable_content
  end

  def destroy
    if @delivery_area.destroy
      redirect_to admin_delivery_areas_path, notice: "削除しました。", status: :see_other
    else
      alert = @delivery_area.errors[:base].first || "配達エリアを削除できませんでした。"
      redirect_to admin_delivery_areas_path, alert:, status: :see_other
    end
  rescue ActiveRecord::InvalidForeignKey
    redirect_to admin_delivery_areas_path, alert: "配達エリアを削除できませんでした。注文履歴や定期注文設定を確認してください。", status: :see_other
  end

  private

  def set_delivery_area
    @delivery_area = DeliveryArea.find(params[:id])
  end

  def delivery_area_params
    params.expect(delivery_area: [ :name, :postal_code, :active ])
  end
end
