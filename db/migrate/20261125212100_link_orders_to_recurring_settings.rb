class LinkOrdersToRecurringSettings < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :recurring_order_setting, foreign_key: true
    add_column :orders, :recurring_served_on, :date, comment: "定期注文を生成した対象日。手動注文では空"
    add_check_constraint :orders, "(recurring_order_setting_id IS NULL) = (recurring_served_on IS NULL)",
      name: "orders_recurring_setting_and_date"
    add_index :orders, [ :recurring_order_setting_id, :recurring_served_on ], unique: true,
      where: "recurring_order_setting_id IS NOT NULL", name: "index_orders_on_recurring_setting_and_date"
    add_index :daily_menus, [ :id, :served_on ], unique: true
    add_foreign_key :orders, :daily_menus, column: [ :daily_menu_id, :recurring_served_on ],
      primary_key: [ :id, :served_on ], name: "fk_orders_recurring_menu_date"
  end
end
