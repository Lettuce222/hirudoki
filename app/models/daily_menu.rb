class DailyMenu < ApplicationRecord
  scope :latest_first, -> { order(served_on: :desc, id: :asc) }

  belongs_to :bento
  before_validation :copy_bento_category

  validates :served_on, presence: true
  validates :category, uniqueness: { scope: :served_on, message: "は同じ提供日にすでに登録されています" }
  validates :capacity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  private

  def copy_bento_category
    self.category = bento&.category
  end
end
