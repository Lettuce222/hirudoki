class Review < ApplicationRecord
  belongs_to :order

  scope :desc_by_created_at, -> { order(created_at: :desc, id: :desc) }

  validates :order_id, uniqueness: true, on: :update
  validates :rating, numericality: { only_integer: true, in: 1..5 }
  validate :order_is_reviewable, on: :create
  around_create :report_duplicate_review

  private

  def order_is_reviewable
    return unless order

    Review.uncached do
      unless Order.exists?(id: order_id, status: :received)
        errors.add(:order, "は受取済みの場合だけ評価できます。")
      end
      errors.add(:order_id, :taken) if Review.exists?(order_id:)
    end
  end

  def report_duplicate_review
    # 一意制約違反が起きても呼び出し元のトランザクションを継続できるようにする。
    Review.transaction(requires_new: true) { yield }
  rescue ActiveRecord::RecordNotUnique => error
    violation = error.cause
    raise unless violation.is_a?(PG::UniqueViolation) &&
      violation.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME) == "index_reviews_on_order_id"

    errors.add(:order_id, :taken)
    raise ActiveRecord::RecordInvalid.new(self)
  end
end
