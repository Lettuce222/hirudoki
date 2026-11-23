class Bento < ApplicationRecord
  BENTO_TYPES = %w[和食 洋食 中華 ヘルシー].freeze

  has_many :daily_menus, dependent: :restrict_with_error
  has_one_attached :image

  validates :name, presence: true
  validates :bento_type, inclusion: { in: BENTO_TYPES }
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :display_order, numericality: { only_integer: true }
  validates :on_sale, inclusion: { in: [ true, false ] }
  validate :bento_type_available_on_offered_dates, on: :update, if: :will_save_change_to_bento_type?

  private

  def bento_type_available_on_offered_dates
    DailyMenu.with_schedule_lock do
      offered_dates = daily_menus.select(:served_on)
      other_menus = DailyMenu.with_bento_type(bento_type).where(served_on: offered_dates).where.not(bento_id: id)
      errors.add(:bento_type, "はこの弁当の提供日にすでに登録されています") if other_menus.exists?
    end
  end
end
