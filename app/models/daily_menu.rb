class DailyMenu < ApplicationRecord
  scope :desc_by_served_on, -> { order(served_on: :desc, id: :asc) }

  belongs_to :bento
  has_many :orders, dependent: :restrict_with_error
  has_many :reviews, through: :orders

  scope :with_bento_type, ->(bento_type) { joins(:bento).where(bentos: { bento_type: }) }

  scope :on_sale, -> { joins(:bento).where(bentos: { on_sale: true }) }
  scope :in_display_order, -> { joins(:bento).order(:served_on, "bentos.display_order", :id) }
  scope :filtered_by, ->(served_on: nil, bento_type: nil) {
    menus = all
    menus = menus.where(served_on:) if served_on.present?
    menus = menus.with_bento_type(bento_type) if bento_type.present?
    menus
  }

  validates :served_on, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :validate_schedule

  # 献立がまだない提供日も保護するため、行ではなく献立テーブルをロックする。
  def self.with_schedule_lock
    transaction do
      with_connection { |connection| connection.execute("LOCK TABLE daily_menus IN SHARE ROW EXCLUSIVE MODE") }
      uncached { yield }
    end
  end

  def self.order_window_open_for?(served_on)
    now = Time.current
    served_on.between?(now.to_date, now.to_date + 14) && now < order_cutoff_at(served_on)
  end

  def self.order_cutoff_at(served_on)
    served_on.in_time_zone.change(hour: 10)
  end

  def accepting_orders?
    DailyMenu.order_window_open_for?(served_on)
  end

  def before_order_cutoff?
    Time.current < DailyMenu.order_cutoff_at(served_on)
  end

  def average_rating
    reviews.average(:rating)
  end

  def remaining_quantity(ordered: orders.not_cancelled.sum(:quantity))
    [ capacity - ordered, 0 ].max
  end

  private

  def validate_schedule
    return unless bento && served_on
    return unless new_record? || will_save_change_to_served_on? || will_save_change_to_bento_id?

    DailyMenu.with_schedule_lock do
      if persisted? && !DailyMenu.exists?(id:, served_on: served_on_in_database, bento_id: bento_id_in_database)
        errors.add(:base, "献立が更新されました。読み込み直してください")
        next
      end

      validate_rescheduled_orders if persisted? && will_save_change_to_served_on?
      unique_bento_type_on_served_on
    end
  end

  def unique_bento_type_on_served_on
    bento_type = bento.new_record? ? bento.bento_type : Bento.where(id: bento_id).pick(:bento_type)
    same_type_menus = DailyMenu.with_bento_type(bento_type).where(served_on:)
    errors.add(:bento, "のタイプは同じ提供日にすでに登録されています") if same_type_menus.where.not(id:).exists?
  end

  def validate_rescheduled_orders
    active_orders = orders.not_cancelled
    # 注文確定と同じ順序で、利用者の行を先にロックする。
    locked_user_ids = User.where(id: active_orders.select(:user_id)).order(:id).lock.ids
    DailyMenu.lock.find(id)

    if orders.where.not(recurring_order_setting_id: nil).exists?
      errors.add(:served_on, "は定期注文があるため変更できません")
      return
    end

    moving_quantities = active_orders.group(:user_id).sum(:quantity)
    # 先行注文で対象者が増えた場合は、ロックの順序を崩さず再入力を促す。
    if (moving_quantities.keys - locked_user_ids).any?
      errors.add(:base, "注文が更新されました。読み込み直してください")
      return
    end

    destination_quantities = Order.not_cancelled.served_on(served_on).where(user_id: moving_quantities.keys).group(:user_id).sum(:quantity)
    if moving_quantities.any? { |user_id, quantity| quantity + destination_quantities.fetch(user_id, 0) > Order::DAILY_LIMIT }
      errors.add(:served_on, "の変更先で同じ利用者の注文が合計#{Order::DAILY_LIMIT}個を超えます")
    end
  end
end
