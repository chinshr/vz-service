# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150426001823) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "roles_mask"
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree
  add_index "admin_users", ["roles_mask"], name: "index_admin_users_on_roles_mask", using: :btree

  create_table "api_client_accesses", force: true do |t|
    t.string   "uid",                                  null: false
    t.integer  "client_id"
    t.string   "access_secret"
    t.integer  "user_id"
    t.string   "device_uid"
    t.string   "device_user_uid"
    t.string   "aasm_state",      default: "inactive", null: false
    t.integer  "access_status"
    t.datetime "activated_at"
    t.datetime "deactivated_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "api_client_accesses", ["aasm_state"], name: "index_api_client_accesses_on_aasm_state", using: :btree
  add_index "api_client_accesses", ["access_status"], name: "index_api_client_accesses_on_access_status", using: :btree
  add_index "api_client_accesses", ["client_id"], name: "index_api_client_accesses_on_client_id", using: :btree
  add_index "api_client_accesses", ["deleted_at"], name: "index_api_client_accesses_on_deleted_at", using: :btree
  add_index "api_client_accesses", ["uid"], name: "index_api_client_accesses_on_uid", unique: true, using: :btree
  add_index "api_client_accesses", ["user_id"], name: "index_api_client_accesses_on_user_id", using: :btree

  create_table "api_clients", force: true do |t|
    t.string   "name"
    t.string   "key",         null: false
    t.integer  "platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "api_clients", ["key"], name: "index_api_clients_on_key", unique: true, using: :btree
  add_index "api_clients", ["platform_id"], name: "index_api_clients_on_platform_id", using: :btree

  create_table "api_devices", force: true do |t|
    t.string   "device_name"
    t.string   "uid",              null: false
    t.integer  "client_id"
    t.integer  "client_access_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "api_devices", ["client_access_id"], name: "index_api_devices_on_client_access_id", using: :btree
  add_index "api_devices", ["client_id"], name: "index_api_devices_on_client_id", using: :btree
  add_index "api_devices", ["uid"], name: "index_api_devices_on_uid", unique: true, using: :btree

  create_table "api_platforms", force: true do |t|
    t.string   "uid",                                 null: false
    t.string   "name"
    t.string   "version"
    t.string   "aasm_state",     default: "inactive", null: false
    t.boolean  "cap",            default: false,      null: false
    t.datetime "activated_at"
    t.datetime "deactivated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "api_platforms", ["aasm_state"], name: "index_api_platforms_on_aasm_state", using: :btree
  add_index "api_platforms", ["uid"], name: "index_api_platforms_on_uid", unique: true, using: :btree

  create_table "attachings", force: true do |t|
    t.integer  "message_id"
    t.integer  "upload_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "attachings", ["message_id", "upload_id"], name: "index_attachings_on_message_id_and_upload_id", unique: true, using: :btree

  create_table "documents", force: true do |t|
    t.string   "title"
    t.string   "slug",                                                                   null: false
    t.text     "description"
    t.integer  "privacy_mask",                                         default: 0,       null: false
    t.string   "locale",            limit: 5,                          default: "en-US", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "html"
    t.integer  "user_id"
    t.json     "rich_text"
    t.text     "text"
    t.integer  "ingest_id"
    t.decimal  "offset",                      precision: 11, scale: 5
    t.decimal  "duration",                    precision: 11, scale: 5
    t.decimal  "start_time",                  precision: 11, scale: 5
    t.decimal  "end_time",                    precision: 11, scale: 5
    t.float    "score"
    t.integer  "position"
    t.string   "type"
    t.integer  "processing_status",                                    default: 0,       null: false
    t.json     "response"
    t.json     "processing_errors"
    t.integer  "track_id"
  end

  add_index "documents", ["created_at"], name: "index_documents_on_created_at", using: :btree
  add_index "documents", ["ingest_id"], name: "index_documents_on_ingest_id", using: :btree
  add_index "documents", ["locale"], name: "index_documents_on_locale", using: :btree
  add_index "documents", ["offset"], name: "index_documents_on_offset", using: :btree
  add_index "documents", ["position"], name: "index_documents_on_position", using: :btree
  add_index "documents", ["privacy_mask"], name: "index_documents_on_privacy_mask", using: :btree
  add_index "documents", ["processing_status"], name: "index_documents_on_processing_status", using: :btree
  add_index "documents", ["score"], name: "index_documents_on_score", using: :btree
  add_index "documents", ["slug"], name: "index_documents_on_slug", unique: true, using: :btree
  add_index "documents", ["title"], name: "index_documents_on_title", using: :btree
  add_index "documents", ["track_id"], name: "index_documents_on_track_id", using: :btree
  add_index "documents", ["type"], name: "index_documents_on_type", using: :btree
  add_index "documents", ["updated_at"], name: "index_documents_on_updated_at", using: :btree
  add_index "documents", ["user_id"], name: "index_documents_on_user_id", using: :btree

  create_table "ingests", force: true do |t|
    t.integer  "upload_id"
    t.string   "type"
    t.string   "aasm_state",   default: "created", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "reset_at"
    t.datetime "removed_at"
    t.datetime "finished_at"
    t.float    "progress",     default: 0.0,       null: false
    t.text     "messages"
    t.string   "stage"
    t.integer  "iteration",    default: 0,         null: false
    t.boolean  "busy",         default: false,     null: false
    t.datetime "restarted_at"
    t.boolean  "terminate",    default: false,     null: false
    t.integer  "document_id"
    t.string   "uid"
  end

  add_index "ingests", ["aasm_state"], name: "index_ingests_on_aasm_state", using: :btree
  add_index "ingests", ["created_at"], name: "index_ingests_on_created_at", using: :btree
  add_index "ingests", ["document_id"], name: "index_ingests_on_document_id", using: :btree
  add_index "ingests", ["finished_at"], name: "index_ingests_on_finished_at", using: :btree
  add_index "ingests", ["iteration"], name: "index_ingests_on_iteration", using: :btree
  add_index "ingests", ["removed_at"], name: "index_ingests_on_removed_at", using: :btree
  add_index "ingests", ["reset_at"], name: "index_ingests_on_reset_at", using: :btree
  add_index "ingests", ["stage"], name: "index_ingests_on_stage", using: :btree
  add_index "ingests", ["started_at"], name: "index_ingests_on_started_at", using: :btree
  add_index "ingests", ["stopped_at"], name: "index_ingests_on_stopped_at", using: :btree
  add_index "ingests", ["type"], name: "index_ingests_on_type", using: :btree
  add_index "ingests", ["uid"], name: "index_ingests_on_uid", using: :btree
  add_index "ingests", ["updated_at"], name: "index_ingests_on_updated_at", using: :btree
  add_index "ingests", ["upload_id"], name: "index_ingests_on_upload_id", using: :btree

  create_table "messages", force: true do |t|
    t.string   "uid",        null: false
    t.string   "from"
    t.text     "to"
    t.text     "cc"
    t.string   "reply_to"
    t.string   "subject"
    t.text     "html"
    t.text     "text"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sender_id"
    t.text     "body"
  end

  add_index "messages", ["sender_id"], name: "index_messages_on_sender_id", using: :btree
  add_index "messages", ["type"], name: "index_messages_on_type", using: :btree
  add_index "messages", ["uid"], name: "index_messages_on_uid", using: :btree

  create_table "registrations", force: true do |t|
    t.string   "email"
    t.string   "locale",       limit: 8
    t.string   "country_code", limit: 2
    t.string   "ip_address"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "time_zone"
    t.decimal  "lat",                    precision: 11, scale: 8
    t.decimal  "lng",                    precision: 11, scale: 8
    t.string   "address"
    t.string   "city"
    t.string   "postal_code"
    t.string   "region_code"
    t.string   "type"
    t.string   "uid"
    t.string   "referrer_uid"
    t.boolean  "opt_in",                                          default: false,     null: false
    t.text     "fields"
    t.text     "user_data"
    t.string   "region_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aasm_state",                                      default: "pending", null: false
    t.datetime "accepted_at"
    t.datetime "declined_at"
  end

  add_index "registrations", ["aasm_state"], name: "index_registrations_on_aasm_state", using: :btree
  add_index "registrations", ["email"], name: "index_registrations_on_email", unique: true, using: :btree
  add_index "registrations", ["referrer_uid"], name: "index_registrations_on_referrer_uid", using: :btree
  add_index "registrations", ["type"], name: "index_registrations_on_type", using: :btree
  add_index "registrations", ["uid"], name: "index_registrations_on_uid", using: :btree

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: true do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "tracks", force: true do |t|
    t.string   "s3_url"
    t.string   "s3_mp3_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "uploads", force: true do |t|
    t.string   "file_name"
    t.string   "file_type"
    t.integer  "file_size"
    t.string   "s3_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.string   "uid"
  end

  add_index "uploads", ["created_at"], name: "index_uploads_on_created_at", using: :btree
  add_index "uploads", ["file_name"], name: "index_uploads_on_file_name", using: :btree
  add_index "uploads", ["file_size"], name: "index_uploads_on_file_size", using: :btree
  add_index "uploads", ["file_type"], name: "index_uploads_on_file_type", using: :btree
  add_index "uploads", ["type"], name: "index_uploads_on_type", using: :btree
  add_index "uploads", ["uid"], name: "index_uploads_on_uid", using: :btree
  add_index "uploads", ["updated_at"], name: "index_uploads_on_updated_at", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                                                     default: "", null: false
    t.string   "encrypted_password",                                        default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                             default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",                                           default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "lat",                              precision: 11, scale: 8
    t.decimal  "lng",                              precision: 11, scale: 8
    t.string   "time_zone"
    t.string   "address"
    t.string   "country_code",           limit: 2
    t.string   "city"
    t.string   "postal_code"
    t.string   "region_code"
    t.string   "region_name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "avatar_url"
    t.string   "css_hex_color"
    t.string   "initials"
    t.integer  "roles_mask"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["lat"], name: "index_users_on_lat", using: :btree
  add_index "users", ["lng"], name: "index_users_on_lng", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["roles_mask"], name: "index_users_on_roles_mask", using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

end
