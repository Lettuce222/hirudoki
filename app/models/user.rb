class User < ApplicationRecord
  BCRYPT_INPUT_BYTES = 72

  devise :database_authenticatable, :validatable

  validates :name, :phone, presence: true
  validates :password_confirmation, presence: true, on: :create
  validate :password_fits_bcrypt

  private

  def password_fits_bcrypt
    return unless password && password.bytesize > BCRYPT_INPUT_BYTES

    bytes = 0
    excess_characters = password.each_grapheme_cluster.count do |character|
      bytes += character.bytesize
      bytes > BCRYPT_INPUT_BYTES
    end
    errors.add(:password, "が長すぎます。入力したパスワードの末尾を#{excess_characters}文字以上短くしてください。")
  end
end
