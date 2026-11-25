class RecurringOrderGeneration
  include ActiveModel::Model
  include ActiveModel::Attributes

  Skip = Data.define(:user_name, :reason)

  attribute :served_on, :date

  attr_reader :orders, :skips

  validates :served_on, presence: true
  validate :served_on_within_order_window

  def generate
    @orders = []
    @skips = []
    return false unless valid?
    return true unless RecurringOrderSetting::WEEKDAYS.cover?(served_on.wday)

    RecurringOrderSetting.active.where(weekday: served_on.wday).find_each do |setting|
      generate_for(setting)
    end
    true
  end

  private

  def served_on_within_order_window
    if served_on && !DailyMenu.order_window_open_for?(served_on)
      errors.add(:served_on, "は注文受付期間内の日付を指定してください。")
    end
  end

  def generate_for(setting)
    user = setting.user
    user.with_lock do
      Order.uncached do
        setting.lock!
        next unless setting.active? && setting.weekday == served_on.wday

        if setting.orders.exists?(recurring_served_on: served_on)
          skip(user, "この対象日は生成済みです。")
          next
        end

        menu = DailyMenu.on_sale.with_bento_type(setting.bento_type).find_by(served_on:)
        unless menu
          skip(user, "販売中の献立がありません。")
          next
        end

        order = user.orders.build(daily_menu: menu, recurring_order_setting: setting, recurring_served_on: served_on,
          delivery_area: setting.delivery_area, delivery_address: setting.delivery_address, quantity: setting.quantity)
        if order.confirm
          orders << order
        else
          skip(user, order.errors.full_messages.join("、"))
        end
      end
    end
  end

  def skip(user, reason)
    skips << Skip.new(user_name: user.name, reason:)
  end
end
