class Administrator < ApplicationRecord
  include PasswordAuthentication

  validates :name, presence: true
end
