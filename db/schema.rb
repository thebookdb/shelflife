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

ActiveRecord::Schema[8.0].define(version: 2025_08_03_053103) do
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

  create_table "libraries", id: :string, default: -> { "ULID()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_libraries_on_name", unique: true
  end

  create_table "library_items", id: :string, default: -> { "ULID()" }, force: :cascade do |t|
    t.string "product_id", null: false
    t.string "library_id", null: false
    t.string "condition"
    t.string "location"
    t.text "notes"
    t.datetime "date_added", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["library_id"], name: "index_library_items_on_library_id"
    t.index ["product_id", "library_id"], name: "index_library_items_on_product_id_and_library_id"
    t.index ["product_id"], name: "index_library_items_on_product_id"
  end

  create_table "products", id: :string, default: -> { "ULID()" }, force: :cascade do |t|
    t.string "ean", null: false
    t.string "title"
    t.string "subtitle"
    t.string "author"
    t.string "publisher"
    t.date "publication_date"
    t.text "description"
    t.string "cover_image_url"
    t.integer "pages"
    t.string "genre"
    t.string "product_type", null: false
    t.json "tbdb_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "valid_barcode", default: true
    t.index ["ean"], name: "index_products_on_ean", unique: true
    t.index ["product_type"], name: "index_products_on_product_type"
  end

  create_table "scans", id: :string, default: -> { "ULID()" }, force: :cascade do |t|
    t.string "product_id", null: false
    t.datetime "scanned_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["product_id"], name: "index_scans_on_product_id"
    t.index ["scanned_at"], name: "index_scans_on_scanned_at"
    t.index ["user_id"], name: "index_scans_on_user_id"
  end

  create_table "sessions", id: :string, default: -> { "ULID()" }, force: :cascade do |t|
    t.string "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", id: :string, default: -> { "ULID()" }, force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.json "user_settings", default: {}
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "library_items", "libraries"
  add_foreign_key "library_items", "products"
  add_foreign_key "scans", "users"
  add_foreign_key "sessions", "users"
end
