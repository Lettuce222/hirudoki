class DeliveryArea < ApplicationRecord
  scope :by_postal_code, -> { order(:postal_code, :id) }

  validates :name, presence: true
  validates :postal_code, format: { with: /\A[0-9]{7}\z/ }, uniqueness: true
  validates :active, inclusion: { in: [ true, false ] }
end
