class DailyMenu < ApplicationRecord
  belongs_to :bento
  before_validation :copy_bento_category

  validates :served_on, presence: true
  validates :category, uniqueness: { scope: :served_on, message: "は同じ提供日にすでに登録されています" }
  validates :capacity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :on_sale, -> { joins(:bento).where(bentos: { on_sale: true }) }

  def self.for_catalog(served_on:, category:)
    menus = on_sale.includes(bento: { image_attachment: :blob }).order(:served_on, "bentos.display_order", :id)
    menus = menus.where(served_on: served_on) if served_on.present?
    menus = menus.where(category: category) if category.present?
    menus
  end

  private

  def copy_bento_category
    self.category = bento&.category
  end
end
