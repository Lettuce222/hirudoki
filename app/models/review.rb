class Review < ApplicationRecord
  belongs_to :order

  validates :order_id, uniqueness: true, on: :update
  validates :rating, numericality: { only_integer: true, in: 1..5 }
  validate :order_is_reviewable, on: :create

  private

  def order_is_reviewable
    return unless order

    # 評価の検証から保存まで、同じ注文への評価や状態変更を待たせる。
    Review.uncached do
      current_order = Order.lock.find_by(id: order_id)
      errors.add(:order, "は受取済みの場合だけ評価できます。") unless current_order&.received?
      errors.add(:order_id, :taken) if Review.exists?(order_id:)
    end
  end
end
