class Admin::BentosController < Admin::CatalogController
  before_action :set_bento, only: %i[edit update destroy]

  def index
    @bentos = Bento.with_attached_image.in_display_order
  end

  def new
    @bento = Bento.new(display_order: 1)
    render :form
  end

  def create
    @bento = Bento.new(bento_params)
    save_record(@bento, admin_bentos_path)
  end

  def edit
    render :form
  end

  def update
    @bento.assign_attributes(bento_params)
    save_record(@bento, admin_bentos_path)
  end

  def destroy
    destroy_record(@bento, admin_bentos_path)
  end

  private

  def set_bento
    @bento = Bento.find(params[:id])
    @registered_image = @bento.image.blob
  end

  def bento_params
    params.expect(bento: [ :name, :description, :category, :price, :display_order, :image, :on_sale ])
  end
end
