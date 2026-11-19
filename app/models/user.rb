class User < ApplicationRecord
  devise :database_authenticatable, :validatable, password_length: 6..72

  validates :name, :phone, presence: true
  validates :password_confirmation, presence: true, on: :create
  validates :password, format: { with: /\A[!-~]+\z/, message: "は半角英数字・記号で入力してください（空白は使えません）" }, allow_blank: true
end
