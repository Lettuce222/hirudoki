class Bento < ApplicationRecord
  CATEGORIES = %w[和食 洋食 中華 ヘルシー].freeze

  has_many :daily_menus, dependent: :restrict_with_error
  has_one_attached :image

  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :display_order, numericality: { only_integer: true }
  validates :on_sale, inclusion: { in: [ true, false ] }
  validate :category_available_on_offered_dates, on: :update, if: :will_save_change_to_category?

  private

  def category_available_on_offered_dates
    if DailyMenu.where(served_on: daily_menus.select(:served_on), category: category).where.not(bento_id: id).exists?
      errors.add(:category, "はこの弁当の提供日にすでに登録されています")
    end
  end
end
