class RecurringOrderSetting < ApplicationRecord
  WEEKDAYS = 1..5

  belongs_to :user
  belongs_to :delivery_area
  has_many :orders, dependent: :restrict_with_error

  scope :active, -> { where(active: true) }

  validates :weekday, numericality: { only_integer: true, in: WEEKDAYS }, uniqueness: { scope: :user_id }
  validates :bento_type, inclusion: { in: Bento::BENTO_TYPES }
  validates :quantity, numericality: { only_integer: true, in: 1..Order::DAILY_LIMIT }
  validates :delivery_address, presence: true
  validates :active, inclusion: { in: [ true, false ] }
  validate :active_delivery_area

  private

  def active_delivery_area
    return unless new_record? || will_save_change_to_delivery_area_id?

    area = delivery_area_id ? DeliveryArea.lock("FOR SHARE").find_by(id: delivery_area_id) : delivery_area
    errors.add(:delivery_area, "は受付を終了しました。") if area && !area.active?
  end
end
