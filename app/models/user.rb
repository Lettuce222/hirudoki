class User < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error
  has_many :recurring_order_settings, dependent: :restrict_with_error

  include PasswordAuthentication

  validates :name, :phone, presence: true
  validates :password_confirmation, presence: true, on: :create

  scope :asc_by_name, -> { order(:name, :id) }

  def monthly_bill(month)
    orders.not_cancelled.served_on(month.all_month).sum(:total_amount)
  end
end
