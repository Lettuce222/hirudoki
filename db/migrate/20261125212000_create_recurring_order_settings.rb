class CreateRecurringOrderSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_order_settings do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :weekday, null: false, comment: "月曜日を1、金曜日を5とする曜日"
      t.string :bento_type, null: false, comment: "生成時に献立を選ぶ弁当タイプ"
      t.integer :quantity, null: false, comment: "週ごとに注文する個数"
      t.references :delivery_area, null: false, foreign_key: true
      t.string :delivery_address, null: false
      t.boolean :active, null: false, default: true, comment: "注文生成の対象に含めるか"
      t.timestamps

      t.index [ :user_id, :weekday ], unique: true
      t.check_constraint "weekday BETWEEN 1 AND 5", name: "recurring_settings_weekday_range"
      t.check_constraint "bento_type IN ('和食', '洋食', '中華', 'ヘルシー')", name: "recurring_settings_known_bento_type"
      t.check_constraint "quantity BETWEEN 1 AND 3", name: "recurring_settings_quantity_range"
    end
  end
end
