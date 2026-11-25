class Order < ApplicationRecord
  TAX_PERCENT = 8
  DAILY_LIMIT = 3

  belongs_to :user
  belongs_to :daily_menu
  belongs_to :delivery_area

  scope :not_cancelled, -> { where.not(status: "キャンセル済") }
  scope :desc_by_created_at, -> { order(created_at: :desc, id: :desc) }

  validates :delivery_address, presence: true
  validates :quantity, numericality: { only_integer: true, in: 1..DAILY_LIMIT }
  validates :status, inclusion: { in: %w[注文済 受取済 キャンセル済] }
  validate :manual_order_available, on: :create

  def self.total_for(unit_price:, quantity:, unit_discount: 0)
    subtotal = [ unit_price - unit_discount, 0 ].max * quantity
    subtotal + subtotal * TAX_PERCENT / 100
  end

  private

  def manual_order_available
    return unless user && daily_menu && delivery_area

    # 同じ利用者の別献立と、別利用者の同じ献立の注文を順番に処理する。
    user.lock!
    daily_menu.lock!
    bento = daily_menu.bento
    bento.lock!("FOR SHARE")
    delivery_area.lock!("FOR SHARE")

    errors.add(:base, "この弁当は販売を終了しました。") unless bento.on_sale?
    errors.add(:base, "この配達エリアは受付を終了しました。") unless delivery_area.active?
    errors.add(:base, "この献立の注文受付期間外です。") unless daily_menu.accepting_orders?
    return if errors.any?

    Order.uncached do
      errors.add(:base, "残数が足りません。") if quantity > daily_menu.remaining_quantity
      ordered = user.orders.not_cancelled.joins(:daily_menu).where(daily_menus: { served_on: daily_menu.served_on }).sum(:quantity)
      errors.add(:base, "同じ提供日には合計3個まで注文できます。") if ordered + quantity > DAILY_LIMIT
    end
    self.unit_price = bento.price
    self.unit_discount = 0
    self.total_amount = Order.total_for(unit_price:, quantity:, unit_discount:)
  end
end
