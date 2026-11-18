class User < ApplicationRecord
  devise :database_authenticatable, :validatable

  validates :name, :phone, presence: true
  validates :password_confirmation, presence: true, on: :create
  validate :password_fits_bcrypt

  private

  def password_fits_bcrypt
    errors.add(:password, "は72バイト以内で入力してください") if password && password.bytesize > 72
  end
end
