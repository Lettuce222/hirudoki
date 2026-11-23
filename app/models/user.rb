class User < ApplicationRecord
  include PasswordAuthentication

  validates :name, :phone, presence: true
  validates :password_confirmation, presence: true, on: :create
end
