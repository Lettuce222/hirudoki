class DailyMenu < ApplicationRecord
  belongs_to :bento

  scope :with_bento_type, ->(bento_type) { joins(:bento).where(bentos: { bento_type: bento_type }) }

  validates :served_on, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :unique_bento_type_on_served_on

  # 献立がまだない提供日も保護するため、行ではなく献立テーブルをロックする。
  def self.with_schedule_lock
    transaction do
      with_connection { |connection| connection.execute("LOCK TABLE daily_menus IN SHARE ROW EXCLUSIVE MODE") }
      uncached { yield }
    end
  end

  private

  def unique_bento_type_on_served_on
    return unless bento && served_on
    return unless new_record? || will_save_change_to_served_on? || will_save_change_to_bento_id?

    DailyMenu.with_schedule_lock do
      if persisted? && !DailyMenu.exists?(id: id, served_on: served_on_in_database, bento_id: bento_id_in_database)
        errors.add(:base, "献立が更新されました。読み込み直してください")
        next
      end

      bento_type = bento.new_record? ? bento.bento_type : Bento.where(id: bento_id).pick(:bento_type)
      same_type_menus = DailyMenu.with_bento_type(bento_type).where(served_on: served_on)
      errors.add(:bento, "のタイプは同じ提供日にすでに登録されています") if same_type_menus.where.not(id: id).exists?
    end
  end
end
