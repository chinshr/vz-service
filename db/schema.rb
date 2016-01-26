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

ActiveRecord::Schema.define(version: 20160204020728) do

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
    t.string   "slug_id",                                                                       null: false
    t.text     "description"
    t.integer  "privacy_mask",                                          default: 0,             null: false
    t.string   "locale",             limit: 5,                          default: "en-US",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "html"
    t.integer  "user_id"
    t.json     "rich_text"
    t.text     "text"
    t.decimal  "offset",                       precision: 15, scale: 3
    t.float    "score"
    t.string   "type"
    t.integer  "processing_status",                                     default: 0,             null: false
    t.json     "response"
    t.json     "processing_errors"
    t.string   "uid"
    t.integer  "ingest_iteration"
    t.integer  "turkee_task_id"
    t.string   "slug"
    t.decimal  "start_time",                   precision: 15, scale: 3
    t.decimal  "end_time",                     precision: 15, scale: 3
    t.string   "aasm_state",                                            default: "unpublished", null: false
    t.datetime "published_at"
    t.integer  "accessibility_mask",                                    default: 0,             null: false
    t.json     "words",                                                 default: []
  end

  add_index "documents", ["aasm_state"], name: "index_documents_on_aasm_state", using: :btree
  add_index "documents", ["accessibility_mask"], name: "index_documents_on_accessibility_mask", using: :btree
  add_index "documents", ["created_at"], name: "index_documents_on_created_at", using: :btree
  add_index "documents", ["ingest_iteration"], name: "index_documents_on_ingest_iteration", using: :btree
  add_index "documents", ["locale"], name: "documents_locale_with_text_pattern_ops", using: :btree
  add_index "documents", ["offset"], name: "index_documents_on_offset", using: :btree
  add_index "documents", ["privacy_mask"], name: "index_documents_on_privacy_mask", using: :btree
  add_index "documents", ["processing_status"], name: "index_documents_on_processing_status", using: :btree
  add_index "documents", ["published_at"], name: "index_documents_on_published_at", using: :btree
  add_index "documents", ["score"], name: "index_documents_on_score", using: :btree
  add_index "documents", ["slug"], name: "index_documents_on_slug", unique: true, using: :btree
  add_index "documents", ["slug_id"], name: "index_documents_on_slug_id", unique: true, using: :btree
  add_index "documents", ["title"], name: "index_documents_on_title", using: :btree
  add_index "documents", ["turkee_task_id"], name: "index_documents_on_turkee_task_id", using: :btree
  add_index "documents", ["type"], name: "index_documents_on_type", using: :btree
  add_index "documents", ["uid"], name: "index_documents_on_uid", using: :btree
  add_index "documents", ["updated_at"], name: "index_documents_on_updated_at", using: :btree
  add_index "documents", ["user_id"], name: "index_documents_on_user_id", using: :btree

  create_table "friendly_id_slugs", force: true do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "image_formats", force: true do |t|
    t.string   "uid"
    t.string   "format"
    t.integer  "width"
    t.integer  "height"
    t.boolean  "is_source",                            default: false, null: false
    t.decimal  "aspect_ratio", precision: 8, scale: 3
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "image_formats", ["aspect_ratio"], name: "index_image_formats_on_aspect_ratio", using: :btree
  add_index "image_formats", ["format"], name: "index_image_formats_on_format", using: :btree
  add_index "image_formats", ["height"], name: "index_image_formats_on_height", using: :btree
  add_index "image_formats", ["uid"], name: "index_image_formats_on_uid", using: :btree
  add_index "image_formats", ["width"], name: "index_image_formats_on_width", using: :btree

  create_table "images", force: true do |t|
    t.string   "uid"
    t.text     "path"
    t.integer  "image_format_id"
    t.integer  "size"
    t.integer  "ingest_id"
    t.integer  "iteration",       default: 0, null: false
    t.datetime "removed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "images", ["image_format_id"], name: "index_images_on_image_format_id", using: :btree
  add_index "images", ["ingest_id"], name: "index_images_on_ingest_id", using: :btree
  add_index "images", ["iteration"], name: "index_images_on_iteration", using: :btree
  add_index "images", ["removed_at"], name: "index_images_on_removed_at", using: :btree
  add_index "images", ["uid"], name: "index_images_on_uid", using: :btree

  create_table "ingest_processes", force: true do |t|
    t.integer  "ingest_id"
    t.integer  "server_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ingest_processes", ["ingest_id", "server_id"], name: "index_ingest_processes_on_ingest_id_and_server_id", unique: true, using: :btree
  add_index "ingest_processes", ["server_id", "ingest_id"], name: "index_ingest_processes_on_server_id_and_ingest_id", unique: true, using: :btree

  create_table "ingest_servers", force: true do |t|
    t.string   "type",                                   null: false
    t.string   "name"
    t.string   "version"
    t.string   "vpc_id"
    t.integer  "tenancy_mask",       default: 0,         null: false
    t.integer  "number",             default: 0,         null: false
    t.integer  "max_processes",      default: 1,         null: false
    t.string   "private_ip_address"
    t.string   "public_ip_address"
    t.string   "instance_id"
    t.string   "region"
    t.string   "dns"
    t.string   "image_id"
    t.string   "instance_type"
    t.datetime "launched_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aasm_state",         default: "pending", null: false
    t.datetime "enabled_at"
    t.datetime "disabled_at"
    t.string   "uid"
  end

  add_index "ingest_servers", ["aasm_state"], name: "index_ingest_servers_on_aasm_state", using: :btree
  add_index "ingest_servers", ["image_id"], name: "index_ingest_servers_on_image_id", using: :btree
  add_index "ingest_servers", ["instance_type"], name: "index_ingest_servers_on_instance_type", using: :btree
  add_index "ingest_servers", ["launched_at"], name: "index_ingest_servers_on_launched_at", using: :btree
  add_index "ingest_servers", ["max_processes"], name: "index_ingest_servers_on_max_processes", using: :btree
  add_index "ingest_servers", ["name"], name: "index_ingest_servers_on_name", using: :btree
  add_index "ingest_servers", ["tenancy_mask"], name: "index_ingest_servers_on_tenancy_mask", using: :btree
  add_index "ingest_servers", ["type"], name: "index_ingest_servers_on_type", using: :btree
  add_index "ingest_servers", ["uid"], name: "index_ingest_servers_on_uid", unique: true, using: :btree
  add_index "ingest_servers", ["version"], name: "index_ingest_servers_on_version", using: :btree
  add_index "ingest_servers", ["vpc_id"], name: "index_ingest_servers_on_vpc_id", using: :btree

  create_table "ingests", force: true do |t|
    t.integer  "upload_id"
    t.string   "type"
    t.string   "aasm_state",                       default: "created", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "reset_at"
    t.datetime "removed_at"
    t.datetime "finished_at"
    t.float    "progress",                         default: 0.0,       null: false
    t.text     "messages"
    t.string   "aasm_stage"
    t.integer  "iteration",                        default: 0,         null: false
    t.boolean  "busy",                             default: false,     null: false
    t.datetime "restarted_at"
    t.boolean  "terminate",                        default: false,     null: false
    t.integer  "document_id"
    t.string   "uid"
    t.boolean  "use_source_annotations",           default: false,     null: false
    t.string   "file_name"
    t.string   "file_type"
    t.integer  "file_size",              limit: 8
    t.text     "source_url"
    t.json     "metadata",                         default: {},        null: false
    t.string   "handle"
    t.text     "origin_url"
    t.integer  "ingestable_id"
    t.string   "ingestable_type"
  end

  add_index "ingests", ["aasm_stage"], name: "index_ingests_on_aasm_stage", using: :btree
  add_index "ingests", ["aasm_state"], name: "index_ingests_on_aasm_state", using: :btree
  add_index "ingests", ["created_at"], name: "index_ingests_on_created_at", using: :btree
  add_index "ingests", ["document_id"], name: "index_ingests_on_document_id", using: :btree
  add_index "ingests", ["file_type"], name: "index_ingests_on_file_type", using: :btree
  add_index "ingests", ["finished_at"], name: "index_ingests_on_finished_at", using: :btree
  add_index "ingests", ["handle"], name: "index_ingests_on_handle", using: :btree
  add_index "ingests", ["ingestable_id", "ingestable_type"], name: "index_ingests_on_ingestable_id_and_ingestable_type", using: :btree
  add_index "ingests", ["iteration"], name: "index_ingests_on_iteration", using: :btree
  add_index "ingests", ["removed_at"], name: "index_ingests_on_removed_at", using: :btree
  add_index "ingests", ["reset_at"], name: "index_ingests_on_reset_at", using: :btree
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

  create_table "segments", force: true do |t|
    t.integer  "document_id"
    t.integer  "track_id"
    t.integer  "ingest_id"
    t.integer  "chunk_id"
    t.integer  "position"
    t.string   "type"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.boolean  "is_master",   default: false, null: false
  end

  add_index "segments", ["chunk_id"], name: "index_segments_on_chunk_id", using: :btree
  add_index "segments", ["created_at"], name: "index_segments_on_created_at", using: :btree
  add_index "segments", ["document_id"], name: "index_segments_on_document_id", using: :btree
  add_index "segments", ["ingest_id"], name: "index_segments_on_ingest_id", using: :btree
  add_index "segments", ["is_master"], name: "index_segments_on_is_master", using: :btree
  add_index "segments", ["position"], name: "index_segments_on_position", using: :btree
  add_index "segments", ["track_id"], name: "index_segments_on_track_id", using: :btree
  add_index "segments", ["type"], name: "index_segments_on_type", using: :btree

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
    t.string   "uid"
    t.integer  "ingest_iteration"
    t.string   "s3_waveform_json_url"
    t.string   "type"
    t.decimal  "duration",             precision: 15, scale: 3
    t.datetime "start_at"
    t.datetime "end_at"
  end

  add_index "tracks", ["duration"], name: "index_tracks_on_duration", using: :btree
  add_index "tracks", ["end_at"], name: "index_tracks_on_end_at", using: :btree
  add_index "tracks", ["ingest_iteration"], name: "index_tracks_on_ingest_iteration", using: :btree
  add_index "tracks", ["start_at"], name: "index_tracks_on_start_at", using: :btree
  add_index "tracks", ["type"], name: "index_tracks_on_type", using: :btree
  add_index "tracks", ["uid"], name: "index_tracks_on_uid", using: :btree

  create_table "turkee_imported_assignments", force: true do |t|
    t.string   "assignment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "turkee_task_id"
    t.string   "worker_id"
    t.integer  "result_id"
  end

  add_index "turkee_imported_assignments", ["assignment_id"], name: "index_turkee_imported_assignments_on_assignment_id", unique: true, using: :btree
  add_index "turkee_imported_assignments", ["turkee_task_id"], name: "index_turkee_imported_assignments_on_turkee_task_id", using: :btree

  create_table "turkee_studies", force: true do |t|
    t.integer  "turkee_task_id"
    t.text     "feedback"
    t.string   "gold_response"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "turkee_studies", ["turkee_task_id"], name: "index_turkee_studies_on_turkee_task_id", using: :btree

  create_table "turkee_tasks", force: true do |t|
    t.string   "hit_url"
    t.boolean  "sandbox"
    t.string   "task_type"
    t.text     "hit_title"
    t.text     "hit_description"
    t.string   "hit_id"
    t.decimal  "hit_reward",            precision: 10, scale: 2
    t.integer  "hit_num_assignments"
    t.integer  "hit_lifetime"
    t.string   "form_url"
    t.integer  "completed_assignments",                          default: 0
    t.boolean  "complete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hit_duration"
    t.integer  "expired"
  end

  create_table "uploads", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.string   "uid"
    t.datetime "recorded_at"
  end

  add_index "uploads", ["created_at"], name: "index_uploads_on_created_at", using: :btree
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
    t.string   "username"
    t.string   "slug"
    t.string   "uid"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["lat"], name: "index_users_on_lat", using: :btree
  add_index "users", ["lng"], name: "index_users_on_lng", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["roles_mask"], name: "index_users_on_roles_mask", using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", unique: true, using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

end
