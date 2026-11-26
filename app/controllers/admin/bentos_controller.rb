class Admin::BentosController < Admin::BaseController
  before_action :set_bento, only: %i[edit update destroy]

  def index
    @bentos = paginate(Bento.with_attached_image.asc_by_display_order)
  end

  def new
    @bento = Bento.new(display_order: 1)
    render :form
  end

  def create
    @bento = Bento.new(bento_params)
    if @bento.save
      redirect_to admin_bentos_path, notice: "保存しました。", status: :see_other
    else
      render :form, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::InvalidForeignKey
    @bento.errors.add(:base, "弁当を保存できませんでした。入力内容を確認してから、もう一度保存してください。")
    render :form, status: :unprocessable_content
  end

  def edit
    render :form
  end

  def update
    if @bento.update(bento_params)
      redirect_to admin_bentos_path, notice: "保存しました。", status: :see_other
    else
      render :form, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::InvalidForeignKey
    @bento.errors.add(:base, "弁当を保存できませんでした。入力内容を確認してから、もう一度保存してください。")
    render :form, status: :unprocessable_content
  end

  def destroy
    if @bento.destroy
      redirect_to admin_bentos_path, notice: "削除しました。", status: :see_other
    else
      alert = @bento.errors[:base].first || "弁当を削除できませんでした。"
      redirect_to admin_bentos_path, alert:, status: :see_other
    end
  rescue ActiveRecord::InvalidForeignKey
    redirect_to admin_bentos_path, alert: "弁当を削除できませんでした。日別献立で使われていないか確認してください。", status: :see_other
  end

  private

  def set_bento
    @bento = Bento.find(params[:id])
    @registered_image = @bento.image.blob
  end

  def bento_params
    params.expect(bento: [ :name, :description, :bento_type, :price, :display_order, :image, :on_sale ])
  end
end
