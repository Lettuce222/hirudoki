class User < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error

  include PasswordAuthentication

  validates :name, :phone, presence: true
  validates :password_confirmation, presence: true, on: :create
end
