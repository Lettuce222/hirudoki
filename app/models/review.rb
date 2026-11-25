class Review < ApplicationRecord
  belongs_to :order

  validates :order_id, uniqueness: true
  validates :rating, numericality: { only_integer: true, in: 1..5 }
  validate :order_was_received, on: :create
  before_create :confirm_order_was_received

  private

  def order_was_received
    errors.add(:order, "は受取済みの場合だけ評価できます。") if order && !order.received?
  end

  def confirm_order_was_received
    # 評価画面を開いた後の管理者による状態変更も確認する。
    order = Order.lock.find(order_id)
    errors.add(:order, "は受取済みの場合だけ評価できます。") unless order.received?
    errors.add(:order_id, :taken) if Review.uncached { Review.exists?(order_id:) }
    throw(:abort) if errors.any?
  end
end
