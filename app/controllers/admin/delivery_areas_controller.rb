class Admin::DeliveryAreasController < Admin::CatalogController
  before_action :set_delivery_area, only: %i[edit update destroy]

  def index
    @delivery_areas = DeliveryArea.by_postal_code
  end

  def new
    @delivery_area = DeliveryArea.new
    render :form
  end

  def create
    @delivery_area = DeliveryArea.new(delivery_area_params)
    save_record(@delivery_area, admin_delivery_areas_path)
  end

  def edit
    render :form
  end

  def update
    @delivery_area.assign_attributes(delivery_area_params)
    save_record(@delivery_area, admin_delivery_areas_path)
  end

  def destroy
    destroy_record(@delivery_area, admin_delivery_areas_path)
  end

  private

  def set_delivery_area
    @delivery_area = DeliveryArea.find(params[:id])
  end

  def delivery_area_params
    params.expect(delivery_area: [ :name, :postal_code, :active ])
  end
end
