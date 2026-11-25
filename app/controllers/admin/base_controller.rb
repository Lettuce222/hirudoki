class Admin::BaseController < ApplicationController
  before_action :no_store
  before_action :authenticate_administrator!

  private

  def save_record(record, index_path)
    if record.save
      redirect_to index_path, notice: "保存しました。", status: :see_other
    else
      render :form, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::InvalidForeignKey
    record.errors.add(:base, "ほかの変更と重複したか、参照先が変更されました。入力内容を確認してください。")
    render :form, status: :unprocessable_content
  end

  def destroy_record(record, index_path)
    if record.destroy
      redirect_to index_path, notice: "削除しました。", status: :see_other
    else
      redirect_to index_path, alert: "参照されているため削除できません。", status: :see_other
    end
  rescue ActiveRecord::InvalidForeignKey
    redirect_to index_path, alert: "参照されているため削除できません。", status: :see_other
  end
end
