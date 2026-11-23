class CreateMenuCatalog < ActiveRecord::Migration[8.1]
  def change
    create_table :bentos do |t|
      t.string :name, null: false
      t.text :description
      t.string :category, null: false
      t.integer :price, null: false
      t.boolean :on_sale, default: true, null: false
      t.integer :display_order, null: false
      t.timestamps
      t.check_constraint "category IN ('和食', '洋食', '中華', 'ヘルシー')", name: "bentos_known_category"
      t.check_constraint "price >= 0", name: "bentos_nonnegative_price"
      t.index [ :id, :category ], unique: true
    end

    create_table :delivery_areas do |t|
      t.string :name, null: false
      t.string :postal_code, null: false, index: { unique: true }
      t.boolean :active, default: true, null: false
      t.timestamps
      t.check_constraint "postal_code ~ '^[0-9]{7}$'", name: "delivery_areas_seven_digit_postal_code"
    end

    create_table :daily_menus do |t|
      t.date :served_on, null: false
      t.references :bento, null: false
      t.string :category, null: false
      t.integer :capacity, null: false
      t.timestamps
      t.check_constraint "capacity >= 0", name: "daily_menus_nonnegative_capacity"
      t.index [ :served_on, :bento_id ], unique: true
      t.index [ :served_on, :category ], unique: true
    end

    # 弁当のタイプ変更でも献立のタイプを一致させ、同日の重複を防ぐ。
    add_foreign_key :daily_menus, :bentos, column: [ :bento_id, :category ], primary_key: [ :id, :category ], on_update: :cascade
  end
end
