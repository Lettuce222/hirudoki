class NormalizeBentoType < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :daily_menus, :bentos
    remove_index :daily_menus, [ :served_on, :category ]
    remove_column :daily_menus, :category
    remove_index :bentos, [ :id, :category ]
    remove_check_constraint :bentos, name: "bentos_known_category"
    rename_column :bentos, :category, :bento_type
    add_check_constraint :bentos, "bento_type IN ('和食', '洋食', '中華', 'ヘルシー')", name: "bentos_known_bento_type"
    add_foreign_key :daily_menus, :bentos
  end

  def down
    remove_foreign_key :daily_menus, :bentos
    remove_check_constraint :bentos, name: "bentos_known_bento_type"
    rename_column :bentos, :bento_type, :category
    add_check_constraint :bentos, "category IN ('和食', '洋食', '中華', 'ヘルシー')", name: "bentos_known_category"
    add_index :bentos, [ :id, :category ], unique: true

    add_column :daily_menus, :category, :string
    execute <<~SQL
      UPDATE daily_menus SET category = bentos.category
      FROM bentos WHERE daily_menus.bento_id = bentos.id
    SQL
    change_column_null :daily_menus, :category, false
    add_index :daily_menus, [ :served_on, :category ], unique: true
    add_foreign_key :daily_menus, :bentos, column: [ :bento_id, :category ], primary_key: [ :id, :category ], on_update: :cascade
  end
end
