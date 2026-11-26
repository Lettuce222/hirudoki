# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_26_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false, comment: "添付先モデルに定義した関連名。弁当画像の関連名はimage"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false, comment: "ストレージ内でファイルを特定するキー。元のファイル名はfilenameに保存する"
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false, comment: "元画像に適用する変換内容のダイジェスト。同じ変換結果を再利用するために使う"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "administrators", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false, comment: "管理者ログイン用のメールアドレス。利用者とは別に一意"
    t.string "encrypted_password", null: false, comment: "管理者認証に使うbcryptハッシュ"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_administrators_on_email", unique: true
  end

  create_table "bentos", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "bento_type", null: false, comment: "和食・洋食・中華・ヘルシーのいずれか。同じ提供日に同じタイプは1献立まで"
    t.integer "price", null: false, comment: "弁当1個あたりの現在の税抜価格（円）。価格変更前の注文額には影響しない"
    t.boolean "on_sale", default: true, null: false, comment: "販売中の弁当だけが利用者の献立閲覧・注文の対象となる"
    t.integer "display_order", null: false, comment: "同じ提供日の献立では小さい値の弁当を先に表示する"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "bento_type::text = ANY (ARRAY['和食'::character varying, '洋食'::character varying, '中華'::character varying, 'ヘルシー'::character varying]::text[])", name: "bentos_known_bento_type"
    t.check_constraint "price >= 0", name: "bentos_nonnegative_price"
  end

  create_table "daily_menus", force: :cascade do |t|
    t.date "served_on", null: false, comment: "日本時間で弁当を提供する日。当日分の手動注文は午前10時に締め切る"
    t.bigint "bento_id", null: false
    t.integer "capacity", null: false, comment: "この献立の手動注文の提供数上限（個）。残数はキャンセル済を除く注文個数を引いて求める"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bento_id"], name: "index_daily_menus_on_bento_id"
    t.index ["id", "served_on"], name: "index_daily_menus_on_id_and_served_on", unique: true
    t.index ["served_on", "bento_id"], name: "index_daily_menus_on_served_on_and_bento_id", unique: true
    t.check_constraint "capacity >= 0", name: "daily_menus_nonnegative_capacity"
  end

  create_table "delivery_areas", force: :cascade do |t|
    t.string "name", null: false
    t.string "postal_code", null: false, comment: "ハイフンなしの半角数字7桁。先頭の0も保持する"
    t.boolean "active", default: true, null: false, comment: "新規注文で選択できる配達エリアかどうか。無効化しても既存注文の参照は保持する"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["postal_code"], name: "index_delivery_areas_on_postal_code", unique: true
    t.check_constraint "postal_code::text ~ '^[0-9]{7}$'::text", name: "delivery_areas_seven_digit_postal_code"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "daily_menu_id", null: false
    t.bigint "delivery_area_id", null: false
    t.string "delivery_address", null: false, comment: "この注文で指定した配達先。次回の初期値には最新の注文の住所を使う"
    t.integer "quantity", null: false, comment: "この注文の弁当の個数。キャンセル後も個数を履歴として保持する"
    t.integer "unit_price", null: false, comment: "注文時点の弁当1個あたりの税抜価格（円）"
    t.integer "unit_discount", default: 0, null: false, comment: "注文時点の弁当1個あたりの税抜割引額（円）。手動注文は0円"
    t.bigint "total_amount", null: false, comment: "この注文の割引後の税込合計（円）。消費税の1円未満を切り捨てて保存する"
    t.string "status", default: "注文済", null: false, comment: "注文済・受取済・キャンセル済。キャンセル済の注文は残数と同日注文数の集計から除外する"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "recurring_order_setting_id"
    t.date "recurring_served_on", comment: "定期注文を生成した対象日。手動注文では空"
    t.index ["daily_menu_id"], name: "index_orders_on_daily_menu_id"
    t.index ["delivery_area_id"], name: "index_orders_on_delivery_area_id"
    t.index ["recurring_order_setting_id", "recurring_served_on"], name: "index_orders_on_recurring_setting_and_date", unique: true, where: "(recurring_order_setting_id IS NOT NULL)"
    t.index ["recurring_order_setting_id"], name: "index_orders_on_recurring_order_setting_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "(recurring_order_setting_id IS NULL) = (recurring_served_on IS NULL)", name: "orders_recurring_setting_and_date"
    t.check_constraint "quantity >= 1 AND quantity <= 3", name: "orders_quantity_range"
    t.check_constraint "status::text = ANY (ARRAY['注文済'::character varying, '受取済'::character varying, 'キャンセル済'::character varying]::text[])", name: "orders_valid_status"
    t.check_constraint "unit_price >= 0 AND unit_discount >= 0 AND total_amount >= 0", name: "orders_nonnegative_amounts"
  end

  create_table "recurring_order_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "weekday", null: false, comment: "月曜日を1、金曜日を5とする曜日"
    t.string "bento_type", null: false, comment: "生成時に献立を選ぶ弁当タイプ"
    t.integer "quantity", null: false, comment: "週ごとに注文する個数"
    t.bigint "delivery_area_id", null: false
    t.string "delivery_address", null: false
    t.boolean "active", default: true, null: false, comment: "注文生成の対象に含めるか"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_area_id"], name: "index_recurring_order_settings_on_delivery_area_id"
    t.index ["user_id", "weekday"], name: "index_recurring_order_settings_on_user_id_and_weekday", unique: true
    t.index ["user_id"], name: "index_recurring_order_settings_on_user_id"
    t.check_constraint "bento_type::text = ANY (ARRAY['和食'::character varying, '洋食'::character varying, '中華'::character varying, 'ヘルシー'::character varying]::text[])", name: "recurring_settings_known_bento_type"
    t.check_constraint "quantity >= 1 AND quantity <= 3", name: "recurring_settings_quantity_range"
    t.check_constraint "weekday >= 1 AND weekday <= 5", name: "recurring_settings_weekday_range"
  end

  create_table "registration_invitations", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "sent_at", comment: "最後の確認メールの送信時刻。再送時に更新して以前の登録リンクを失効させる"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", comment: "この招待で登録した利用者。未使用の招待はNULL"
    t.index ["email"], name: "index_registration_invitations_on_email", unique: true
    t.index ["user_id"], name: "index_registration_invitations_on_user_id", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.integer "rating", null: false, comment: "利用者が受取済み注文に付けた1から5の評価"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_reviews_on_order_id", unique: true
    t.check_constraint "rating >= 1 AND rating <= 5", name: "reviews_rating_range"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false, comment: "利用者ログイン用のメールアドレス。利用者内で一意"
    t.string "encrypted_password", null: false, comment: "Deviseが認証に使うbcryptハッシュ"
    t.string "phone", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "daily_menus", "bentos"
  add_foreign_key "orders", "daily_menus"
  add_foreign_key "orders", "daily_menus", column: ["daily_menu_id", "recurring_served_on"], primary_key: ["id", "served_on"], name: "fk_orders_recurring_menu_date"
  add_foreign_key "orders", "delivery_areas"
  add_foreign_key "orders", "recurring_order_settings"
  add_foreign_key "orders", "users"
  add_foreign_key "recurring_order_settings", "delivery_areas"
  add_foreign_key "recurring_order_settings", "users"
  add_foreign_key "registration_invitations", "users"
  add_foreign_key "reviews", "orders"
end
