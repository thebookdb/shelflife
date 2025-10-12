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

ActiveRecord::Schema[8.0].define(version: 2025_10_11_014729) do
  create_table "acquisition_sources", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_acquisition_sources_on_active"
    t.index ["name"], name: "index_acquisition_sources_on_name", unique: true
  end

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

  create_table "item_statuses", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_item_statuses_on_active"
    t.index ["name"], name: "index_item_statuses_on_name", unique: true
  end

  create_table "libraries", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "virtual", default: false, null: false
    t.integer "visibility", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_libraries_on_name", unique: true
    t.index ["virtual"], name: "index_libraries_on_virtual"
  end

  create_table "library_items", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "library_id", null: false
    t.string "condition"
    t.string "location"
    t.text "notes"
    t.datetime "date_added", default: -> { "CURRENT_TIMESTAMP" }
    t.date "acquisition_date"
    t.integer "acquisition_source_id"
    t.decimal "acquisition_price", precision: 8, scale: 2
    t.integer "ownership_status_id"
    t.string "copy_identifier"
    t.text "condition_notes"
    t.date "last_condition_check"
    t.text "damage_description"
    t.integer "item_status_id"
    t.string "lent_to"
    t.date "due_date"
    t.decimal "replacement_cost", precision: 8, scale: 2
    t.decimal "original_retail_price", precision: 8, scale: 2
    t.decimal "current_market_value", precision: 8, scale: 2
    t.text "private_notes"
    t.string "tags"
    t.datetime "last_accessed"
    t.boolean "is_favorite", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acquisition_source_id"], name: "index_library_items_on_acquisition_source_id"
    t.index ["item_status_id"], name: "index_library_items_on_item_status_id"
    t.index ["library_id"], name: "index_library_items_on_library_id"
    t.index ["ownership_status_id"], name: "index_library_items_on_ownership_status_id"
    t.index ["product_id", "library_id"], name: "index_library_items_on_product_id_and_library_id"
    t.index ["product_id"], name: "index_library_items_on_product_id"
  end

  create_table "ownership_statuses", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_ownership_statuses_on_active"
    t.index ["name"], name: "index_ownership_statuses_on_name", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "gtin", null: false
    t.boolean "valid_barcode", default: true
    t.string "title"
    t.string "subtitle"
    t.string "author"
    t.string "publisher"
    t.date "publication_date"
    t.text "description"
    t.string "cover_image_url"
    t.integer "pages"
    t.string "genre"
    t.integer "product_type", default: 1, null: false
    t.json "tbdb_data"
    t.text "notes"
    t.string "players"
    t.string "age_range"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gtin"], name: "index_products_on_gtin", unique: true
    t.index ["product_type"], name: "index_products_on_product_type"
  end

  create_table "scans", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "user_id", null: false
    t.datetime "scanned_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_scans_on_product_id"
    t.index ["scanned_at"], name: "index_scans_on_scanned_at"
    t.index ["user_id"], name: "index_scans_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tbdb_connections", force: :cascade do |t|
    t.string "client_id"
    t.string "client_secret"
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_base_url"
    t.string "status", default: "connected"
    t.datetime "verified_at"
    t.text "last_error"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "name"
    t.boolean "admin", default: false, null: false
    t.json "user_settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "library_items", "acquisition_sources"
  add_foreign_key "library_items", "item_statuses"
  add_foreign_key "library_items", "libraries"
  add_foreign_key "library_items", "ownership_statuses"
  add_foreign_key "library_items", "products"
  add_foreign_key "scans", "products"
  add_foreign_key "scans", "users"
  add_foreign_key "sessions", "users"
end
