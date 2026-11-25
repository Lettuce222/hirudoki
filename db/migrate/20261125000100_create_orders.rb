class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :daily_menu, null: false, foreign_key: true
      t.references :delivery_area, null: false, foreign_key: true
      t.string :delivery_address, null: false
      t.integer :quantity, null: false
      t.integer :unit_price, null: false
      t.integer :unit_discount, null: false, default: 0
      t.bigint :total_amount, null: false
      t.string :status, null: false, default: "注文済"
      t.timestamps

      t.check_constraint "quantity BETWEEN 1 AND 3", name: "orders_quantity_range"
      t.check_constraint "unit_price >= 0 AND unit_discount >= 0 AND total_amount >= 0", name: "orders_nonnegative_amounts"
      t.check_constraint "status IN ('注文済', '受取済', 'キャンセル済')", name: "orders_valid_status"
    end
  end
end
