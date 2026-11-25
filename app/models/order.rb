class Order < ApplicationRecord
  TAX_RATE = BigDecimal("0.08")
  DAILY_LIMIT = 3

  belongs_to :user
  belongs_to :daily_menu
  belongs_to :delivery_area

  enum :status, { ordered: "注文済", received: "受取済", cancelled: "キャンセル済" }, validate: true

  scope :desc_by_created_at, -> { order(created_at: :desc, id: :desc) }

  validates :delivery_address, presence: true
  validates :quantity, numericality: { only_integer: true, in: 1..DAILY_LIMIT }
  validate :order_availability, on: :create

  def self.total_for(unit_price:, quantity:, unit_discount: 0)
    subtotal = [ unit_price - unit_discount, 0 ].max * quantity
    subtotal + (subtotal * TAX_RATE).floor
  end

  def confirm
    return false unless new_record?

    Order.transaction do
      lock_for_confirmation
      set_price
      Order.uncached { save }
    end
  end

  private

  def lock_for_confirmation
    # 同じ利用者の別献立と、別利用者の同じ献立の注文を順番に処理する。
    user&.lock!
    daily_menu&.lock!
    daily_menu&.bento&.lock!("FOR SHARE")
    delivery_area&.lock!("FOR SHARE")
  end

  def set_price
    return unless daily_menu && quantity

    self.unit_price = daily_menu.bento.price
    self.unit_discount = 0
    self.total_amount = Order.total_for(unit_price:, quantity:, unit_discount:)
  end

  def order_availability
    return if errors.any?

    errors.add(:base, "この弁当は販売を終了しました。") unless daily_menu.bento.on_sale?
    errors.add(:base, "この配達エリアは受付を終了しました。") unless delivery_area.active?
    errors.add(:base, "この献立の注文受付期間外です。") unless daily_menu.accepting_orders?
    return if errors.any?

    errors.add(:base, "残数が足りません。") if quantity > daily_menu.remaining_quantity
    ordered = user.orders.not_cancelled.joins(:daily_menu).where(daily_menus: { served_on: daily_menu.served_on }).sum(:quantity)
    errors.add(:base, "同じ提供日には合計3個まで注文できます。") if ordered + quantity > DAILY_LIMIT
  end
end
