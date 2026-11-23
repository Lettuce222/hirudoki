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

ActiveRecord::Schema[8.1].define(version: 2026_11_23_000100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bentos", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "category", null: false
    t.integer "price", null: false
    t.boolean "on_sale", default: true, null: false
    t.integer "display_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id", "category"], name: "index_bentos_on_id_and_category", unique: true
    t.check_constraint "category::text = ANY (ARRAY['和食'::character varying, '洋食'::character varying, '中華'::character varying, 'ヘルシー'::character varying]::text[])", name: "bentos_known_category"
    t.check_constraint "price >= 0", name: "bentos_nonnegative_price"
  end

  create_table "daily_menus", force: :cascade do |t|
    t.date "served_on", null: false
    t.bigint "bento_id", null: false
    t.string "category", null: false
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bento_id"], name: "index_daily_menus_on_bento_id"
    t.index ["served_on", "bento_id"], name: "index_daily_menus_on_served_on_and_bento_id", unique: true
    t.index ["served_on", "category"], name: "index_daily_menus_on_served_on_and_category", unique: true
    t.check_constraint "capacity >= 0", name: "daily_menus_nonnegative_capacity"
  end

  create_table "delivery_areas", force: :cascade do |t|
    t.string "name", null: false
    t.string "postal_code", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["postal_code"], name: "index_delivery_areas_on_postal_code", unique: true
    t.check_constraint "postal_code::text ~ '^[0-9]{7}$'::text", name: "delivery_areas_seven_digit_postal_code"
  end

  create_table "registration_invitations", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["email"], name: "index_registration_invitations_on_email", unique: true
    t.index ["user_id"], name: "index_registration_invitations_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "phone", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "daily_menus", "bentos", column: ["bento_id", "category"], primary_key: ["id", "category"], on_update: :cascade
  add_foreign_key "registration_invitations", "users"
end
