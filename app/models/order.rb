class Order < ApplicationRecord
  TAX_RATE = BigDecimal("0.08")
  DAILY_LIMIT = 3

  belongs_to :user
  belongs_to :daily_menu
  belongs_to :delivery_area
  has_one :review, dependent: :restrict_with_error

  enum :status, { ordered: "注文済", received: "受取済", cancelled: "キャンセル済" }, validate: true

  scope :desc_by_created_at, -> { order(created_at: :desc, id: :desc) }
  scope :served_on, ->(dates) { joins(:daily_menu).where(daily_menus: { served_on: dates }) }

  validates :delivery_address, presence: true
  validates :quantity, numericality: { only_integer: true, in: 1..DAILY_LIMIT }
  validate :order_availability, on: :create

  scope :for_administration, -> { includes(:user, :delivery_area, daily_menu: :bento).desc_by_created_at }

  def self.production_quantities(date)
    not_cancelled.served_on(date).joins(daily_menu: :bento)
      .group("bentos.id", "bentos.name").order("bentos.name", "bentos.id").sum(:quantity)
  end

  def self.for_delivery(date)
    not_cancelled.served_on(date).preload(:user, :delivery_area, daily_menu: :bento)
      .order(:delivery_area_id, :id)
  end

  def self.total_for(unit_price:, quantity:, unit_discount: 0)
    subtotal = [ unit_price - unit_discount, 0 ].max * quantity
    subtotal + (subtotal * TAX_RATE).floor
  end

  def confirm
    return false unless new_record?

    with_locked_user_and_menu do
      daily_menu&.bento&.lock!("FOR SHARE")
      delivery_area&.lock!("FOR SHARE")
      set_price
      save
    end
  end

  def recurring?
    # 定期注文のマイグレーション前は手動注文だけを扱う。
    has_attribute?(:recurring_order_setting_id) && self[:recurring_order_setting_id].present?
  end

  def changeable?
    persisted? && ordered? && daily_menu.before_order_cutoff?
  end

  def reviewable?
    persisted? && received? && review.nil?
  end

  def change_quantity(new_quantity)
    with_order_change_lock do
      next false unless customer_change_allowed?

      self.quantity = new_quantity
      next false unless valid?

      menu_orders = daily_menu.orders.not_cancelled.where.not(id:)
      user_orders = user.orders.not_cancelled.where.not(id:)
      check_quantity_limits(menu_orders:, user_orders:)
      next false if errors.any?

      update(total_amount: Order.total_for(unit_price:, unit_discount:, quantity:))
    end
  end

  def cancel
    with_order_change_lock do
      customer_change_allowed? && cancelled!
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  def change_status_by_administrator(new_status)
    with_order_change_lock do
      errors.clear
      unless Order.statuses.key?(new_status)
        errors.add(:status, :inclusion)
        next false
      end

      if cancelled? && new_status.to_s != "cancelled"
        check_quantity_limits(menu_orders: daily_menu.orders.not_cancelled, user_orders: user.orders.not_cancelled)
      end
      errors.empty? && update(status: new_status)
    end
  end

  private

  def with_order_change_lock
    return false unless persisted?

    with_locked_user_and_menu do
      reload(lock: true)
      yield
    end
  end

  def customer_change_allowed?
    errors.clear
    return true if changeable?

    errors.add(:base, "この注文は変更・キャンセルできません。")
    false
  end

  def with_locked_user_and_menu
    Order.transaction do
      # 同じ利用者の別献立と、別利用者の同じ献立の注文を順番に処理する。
      user&.lock!
      daily_menu&.lock!
      Order.uncached { yield }
    end
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

    check_quantity_limits(menu_orders: daily_menu.orders.not_cancelled, user_orders: user.orders.not_cancelled)
  end

  def check_quantity_limits(menu_orders:, user_orders:)
    remaining = daily_menu.remaining_quantity(ordered: menu_orders.sum(:quantity))
    errors.add(:base, "残数が足りません。") if quantity > remaining
    ordered = user_orders.served_on(daily_menu.served_on).sum(:quantity)
    errors.add(:base, "同じ提供日には合計3個まで注文できます。") if ordered + quantity > DAILY_LIMIT
  end
end
