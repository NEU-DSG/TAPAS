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

ActiveRecord::Schema[8.1].define(version: 2026_01_13_171831) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "collection_core_files", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "core_file_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "core_file_id"], name: "index_collection_core_files_on_collection_and_core_file", unique: true
    t.index ["collection_id"], name: "index_collection_core_files_on_collection_id"
    t.index ["core_file_id"], name: "index_collection_core_files_on_core_file_id"
  end

  create_table "collections", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "depositor_id", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.boolean "is_public"
    t.integer "project_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["depositor_id"], name: "index_collections_on_depositor_id"
    t.index ["discarded_at"], name: "index_collections_on_discarded_at"
  end

  create_table "core_files", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "depositor_id", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.boolean "featured"
    t.boolean "is_public", default: true
    t.text "mods_xml", size: :medium
    t.string "ography_type"
    t.text "processing_error"
    t.string "processing_status", default: "pending"
    t.string "tapas_xq_doc_id"
    t.string "tapas_xq_project_id"
    t.text "tei_authors"
    t.text "tei_contributors"
    t.text "tfe_xml"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["processing_status"], name: "index_core_files_on_processing_status"
    t.index ["tapas_xq_project_id", "tapas_xq_doc_id"], name: "index_core_files_on_tapas_xq_ids", unique: true
  end

  create_table "image_files", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "depositor_id", null: false
    t.text "description"
    t.string "file_format"
    t.string "image_url"
    t.bigint "imageable_id", null: false
    t.string "imageable_type", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["imageable_type", "imageable_id"], name: "index_image_files_on_imageable_type_and_imageable_id"
  end

  create_table "project_members", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_project_depositor"
    t.bigint "project_id"
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["project_id"], name: "index_project_members_on_project_id"
    t.index ["user_id"], name: "index_project_members_on_user_id"
  end

  create_table "projects", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "depositor_id", null: false
    t.text "description"
    t.string "institution"
    t.boolean "is_public", default: true
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["depositor_id"], name: "index_projects_on_depositor_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "admin_at"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "institution"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "view_packages", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "css_files"
    t.text "description"
    t.string "dir_name"
    t.text "file_type"
    t.string "git_branch"
    t.datetime "git_timestamp"
    t.string "human_name"
    t.text "js_files"
    t.string "machine_name"
    t.text "parameters"
    t.text "run_process"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "collection_core_files", "collections"
  add_foreign_key "collection_core_files", "core_files"
end
