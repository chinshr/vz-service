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

ActiveRecord::Schema.define(version: 20170525220429) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace",     limit: 255
    t.text     "body"
    t.string   "resource_id",   limit: 255, null: false
    t.string   "resource_type", limit: 255, null: false
    t.integer  "author_id"
    t.string   "author_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree
  end

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "roles_mask"
    t.index ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree
    t.index ["roles_mask"], name: "index_admin_users_on_roles_mask", using: :btree
  end

  create_table "api_client_accesses", force: :cascade do |t|
    t.string   "uid",             limit: 255,                      null: false
    t.integer  "client_id"
    t.string   "access_secret",   limit: 255
    t.integer  "user_id"
    t.string   "device_uid",      limit: 255
    t.string   "device_user_uid", limit: 255
    t.string   "aasm_state",      limit: 255, default: "inactive", null: false
    t.integer  "access_status"
    t.datetime "activated_at"
    t.datetime "deactivated_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["aasm_state"], name: "index_api_client_accesses_on_aasm_state", using: :btree
    t.index ["access_status"], name: "index_api_client_accesses_on_access_status", using: :btree
    t.index ["client_id"], name: "index_api_client_accesses_on_client_id", using: :btree
    t.index ["deleted_at"], name: "index_api_client_accesses_on_deleted_at", using: :btree
    t.index ["uid"], name: "index_api_client_accesses_on_uid", unique: true, using: :btree
    t.index ["user_id"], name: "index_api_client_accesses_on_user_id", using: :btree
  end

  create_table "api_clients", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "key",         limit: 255, null: false
    t.integer  "platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["key"], name: "index_api_clients_on_key", unique: true, using: :btree
    t.index ["platform_id"], name: "index_api_clients_on_platform_id", using: :btree
  end

  create_table "api_devices", force: :cascade do |t|
    t.string   "device_name",      limit: 255
    t.string   "uid",              limit: 255, null: false
    t.integer  "client_id"
    t.integer  "client_access_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["client_access_id"], name: "index_api_devices_on_client_access_id", using: :btree
    t.index ["client_id"], name: "index_api_devices_on_client_id", using: :btree
    t.index ["uid"], name: "index_api_devices_on_uid", unique: true, using: :btree
  end

  create_table "api_platforms", force: :cascade do |t|
    t.string   "uid",            limit: 255,                      null: false
    t.string   "name",           limit: 255
    t.string   "version",        limit: 255
    t.string   "aasm_state",     limit: 255, default: "inactive", null: false
    t.boolean  "cap",                        default: false,      null: false
    t.datetime "activated_at"
    t.datetime "deactivated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["aasm_state"], name: "index_api_platforms_on_aasm_state", using: :btree
    t.index ["uid"], name: "index_api_platforms_on_uid", unique: true, using: :btree
  end

  create_table "attachings", force: :cascade do |t|
    t.integer  "message_id"
    t.integer  "upload_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["message_id", "upload_id"], name: "index_attachings_on_message_id_and_upload_id", unique: true, using: :btree
  end

  create_table "documents", force: :cascade do |t|
    t.string   "title",                 limit: 255
    t.string   "slug_id",               limit: 255,                                                  null: false
    t.text     "description"
    t.integer  "privacy_mask",                                               default: 0,             null: false
    t.string   "locale",                limit: 5,                            default: "en-US",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "html"
    t.integer  "user_id"
    t.json     "rich_text"
    t.text     "text"
    t.decimal  "offset",                            precision: 15, scale: 3
    t.float    "score"
    t.string   "type",                  limit: 255
    t.integer  "processing_status",                                          default: 0,             null: false
    t.jsonb    "response",                                                   default: {},            null: false
    t.string   "uid",                   limit: 255
    t.integer  "ingest_iteration"
    t.integer  "turkee_task_id"
    t.string   "slug",                  limit: 255
    t.decimal  "start_time",                        precision: 15, scale: 3
    t.decimal  "end_time",                          precision: 15, scale: 3
    t.string   "aasm_state",            limit: 255,                          default: "unpublished", null: false
    t.datetime "published_at"
    t.integer  "accessibility_mask",                                         default: 0,             null: false
    t.datetime "removed_at"
    t.datetime "deleted_at"
    t.integer  "processed_stages_mask",                                      default: 0,             null: false
    t.index "locale text_pattern_ops", name: "documents_locale_with_text_pattern_ops", using: :btree
    t.index ["aasm_state"], name: "index_documents_on_aasm_state", using: :btree
    t.index ["accessibility_mask"], name: "index_documents_on_accessibility_mask", using: :btree
    t.index ["created_at"], name: "index_documents_on_created_at", using: :btree
    t.index ["deleted_at"], name: "index_documents_on_deleted_at", using: :btree
    t.index ["ingest_iteration"], name: "index_documents_on_ingest_iteration", using: :btree
    t.index ["offset"], name: "index_documents_on_offset", using: :btree
    t.index ["privacy_mask"], name: "index_documents_on_privacy_mask", using: :btree
    t.index ["processed_stages_mask"], name: "index_documents_on_processed_stages_mask", using: :btree
    t.index ["processing_status"], name: "index_documents_on_processing_status", using: :btree
    t.index ["published_at"], name: "index_documents_on_published_at", using: :btree
    t.index ["removed_at"], name: "index_documents_on_removed_at", using: :btree
    t.index ["response"], name: "index_documents_on_response", using: :gin
    t.index ["score"], name: "index_documents_on_score", using: :btree
    t.index ["slug"], name: "index_documents_on_slug", unique: true, using: :btree
    t.index ["slug_id"], name: "index_documents_on_slug_id", unique: true, using: :btree
    t.index ["title"], name: "index_documents_on_title", using: :btree
    t.index ["turkee_task_id"], name: "index_documents_on_turkee_task_id", using: :btree
    t.index ["type"], name: "index_documents_on_type", using: :btree
    t.index ["uid"], name: "index_documents_on_uid", using: :btree
    t.index ["updated_at"], name: "index_documents_on_updated_at", using: :btree
    t.index ["user_id"], name: "index_documents_on_user_id", using: :btree
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.integer  "sluggable_id",               null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 255
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree
  end

  create_table "image_formats", force: :cascade do |t|
    t.string   "uid",          limit: 255
    t.string   "format",       limit: 255
    t.integer  "width"
    t.integer  "height"
    t.boolean  "is_source",                                        default: false, null: false
    t.decimal  "aspect_ratio",             precision: 8, scale: 3
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["aspect_ratio"], name: "index_image_formats_on_aspect_ratio", using: :btree
    t.index ["format"], name: "index_image_formats_on_format", using: :btree
    t.index ["height"], name: "index_image_formats_on_height", using: :btree
    t.index ["uid"], name: "index_image_formats_on_uid", using: :btree
    t.index ["width"], name: "index_image_formats_on_width", using: :btree
  end

  create_table "images", force: :cascade do |t|
    t.string   "uid",             limit: 255
    t.text     "path"
    t.integer  "image_format_id"
    t.integer  "size"
    t.integer  "ingest_id"
    t.integer  "iteration",                                           default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "width"
    t.integer  "height"
    t.string   "format",          limit: 255
    t.decimal  "aspect_ratio",                precision: 8, scale: 3
    t.index ["deleted_at"], name: "index_images_on_deleted_at", using: :btree
    t.index ["image_format_id"], name: "index_images_on_image_format_id", using: :btree
    t.index ["ingest_id"], name: "index_images_on_ingest_id", using: :btree
    t.index ["iteration"], name: "index_images_on_iteration", using: :btree
    t.index ["uid"], name: "index_images_on_uid", using: :btree
  end

  create_table "ingest_servers", force: :cascade do |t|
    t.string   "type",               limit: 255,                     null: false
    t.string   "name",               limit: 255
    t.string   "version",            limit: 255
    t.string   "vpc_id",             limit: 255
    t.integer  "tenancy_mask",                   default: 0,         null: false
    t.integer  "number",                         default: 0,         null: false
    t.integer  "max_workers",                    default: 1,         null: false
    t.string   "private_ip_address", limit: 255
    t.string   "public_ip_address",  limit: 255
    t.string   "instance_id",        limit: 255
    t.string   "region",             limit: 255
    t.string   "dns",                limit: 255
    t.string   "image_id",           limit: 255
    t.string   "instance_type",      limit: 255
    t.datetime "launched_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aasm_state",         limit: 255, default: "pending", null: false
    t.datetime "enabled_at"
    t.datetime "disabled_at"
    t.string   "uid",                limit: 255
    t.datetime "deleted_at"
    t.datetime "stopped_at"
    t.datetime "terminated_at"
    t.index ["aasm_state"], name: "index_ingest_servers_on_aasm_state", using: :btree
    t.index ["deleted_at"], name: "index_ingest_servers_on_deleted_at", using: :btree
    t.index ["image_id"], name: "index_ingest_servers_on_image_id", using: :btree
    t.index ["instance_type"], name: "index_ingest_servers_on_instance_type", using: :btree
    t.index ["launched_at"], name: "index_ingest_servers_on_launched_at", using: :btree
    t.index ["max_workers"], name: "index_ingest_servers_on_max_workers", using: :btree
    t.index ["name"], name: "index_ingest_servers_on_name", using: :btree
    t.index ["stopped_at"], name: "index_ingest_servers_on_stopped_at", using: :btree
    t.index ["tenancy_mask"], name: "index_ingest_servers_on_tenancy_mask", using: :btree
    t.index ["terminated_at"], name: "index_ingest_servers_on_terminated_at", using: :btree
    t.index ["type"], name: "index_ingest_servers_on_type", using: :btree
    t.index ["uid"], name: "index_ingest_servers_on_uid", unique: true, using: :btree
    t.index ["version"], name: "index_ingest_servers_on_version", using: :btree
    t.index ["vpc_id"], name: "index_ingest_servers_on_vpc_id", using: :btree
  end

  create_table "ingest_workers", force: :cascade do |t|
    t.string   "uid"
    t.integer  "ingest_id"
    t.integer  "ingest_iteration"
    t.integer  "server_id"
    t.string   "worker_name"
    t.string   "aasm_state",       default: "created", null: false
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "finished_at"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.json     "messages",         default: {},        null: false
    t.string   "instance_id"
    t.integer  "lock_count",       default: 0,         null: false
    t.string   "worker_object_id"
    t.datetime "failed_at"
    t.index ["aasm_state"], name: "index_ingest_workers_on_aasm_state", using: :btree
    t.index ["created_at"], name: "index_ingest_workers_on_created_at", using: :btree
    t.index ["failed_at"], name: "index_ingest_workers_on_failed_at", using: :btree
    t.index ["finished_at"], name: "index_ingest_workers_on_finished_at", using: :btree
    t.index ["ingest_id"], name: "index_ingest_workers_on_ingest_id", using: :btree
    t.index ["ingest_iteration"], name: "index_ingest_workers_on_ingest_iteration", using: :btree
    t.index ["server_id"], name: "index_ingest_workers_on_server_id", using: :btree
    t.index ["started_at"], name: "index_ingest_workers_on_started_at", using: :btree
    t.index ["stopped_at"], name: "index_ingest_workers_on_stopped_at", using: :btree
    t.index ["uid"], name: "index_ingest_workers_on_uid", using: :btree
    t.index ["worker_name"], name: "index_ingest_workers_on_worker_name", using: :btree
  end

  create_table "ingests", force: :cascade do |t|
    t.integer  "upload_id"
    t.string   "type",                   limit: 255
    t.string   "aasm_state",             limit: 255, default: "created", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "reset_at"
    t.datetime "removed_at"
    t.datetime "finished_at"
    t.float    "progress",                           default: 0.0,       null: false
    t.string   "aasm_stage",             limit: 255
    t.integer  "iteration",                          default: 0,         null: false
    t.boolean  "busy",                               default: false,     null: false
    t.datetime "restarted_at"
    t.boolean  "terminate",                          default: false,     null: false
    t.integer  "document_id"
    t.string   "uid",                    limit: 255
    t.boolean  "use_source_annotations",             default: false,     null: false
    t.string   "file_name",              limit: 255
    t.string   "file_type",              limit: 255
    t.bigint   "file_size"
    t.text     "source_url"
    t.json     "metadata",                           default: {},        null: false
    t.string   "handle",                 limit: 255
    t.text     "origin_url"
    t.integer  "ingestable_id"
    t.string   "ingestable_type",        limit: 255
    t.datetime "deleted_at"
    t.json     "messages",                           default: {},        null: false
    t.index ["aasm_stage"], name: "index_ingests_on_aasm_stage", using: :btree
    t.index ["aasm_state"], name: "index_ingests_on_aasm_state", using: :btree
    t.index ["created_at"], name: "index_ingests_on_created_at", using: :btree
    t.index ["deleted_at"], name: "index_ingests_on_deleted_at", using: :btree
    t.index ["document_id"], name: "index_ingests_on_document_id", using: :btree
    t.index ["file_type"], name: "index_ingests_on_file_type", using: :btree
    t.index ["finished_at"], name: "index_ingests_on_finished_at", using: :btree
    t.index ["handle"], name: "index_ingests_on_handle", using: :btree
    t.index ["ingestable_id", "ingestable_type"], name: "index_ingests_on_ingestable_id_and_ingestable_type", using: :btree
    t.index ["iteration"], name: "index_ingests_on_iteration", using: :btree
    t.index ["removed_at"], name: "index_ingests_on_removed_at", using: :btree
    t.index ["reset_at"], name: "index_ingests_on_reset_at", using: :btree
    t.index ["started_at"], name: "index_ingests_on_started_at", using: :btree
    t.index ["stopped_at"], name: "index_ingests_on_stopped_at", using: :btree
    t.index ["type"], name: "index_ingests_on_type", using: :btree
    t.index ["uid"], name: "index_ingests_on_uid", using: :btree
    t.index ["updated_at"], name: "index_ingests_on_updated_at", using: :btree
    t.index ["upload_id"], name: "index_ingests_on_upload_id", using: :btree
  end

  create_table "messages", force: :cascade do |t|
    t.string   "uid",         limit: 255, null: false
    t.string   "from",        limit: 255
    t.text     "to"
    t.text     "cc"
    t.string   "reply_to",    limit: 255
    t.string   "subject",     limit: 255
    t.text     "html"
    t.text     "text"
    t.string   "type",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sender_id"
    t.text     "body"
    t.string   "sender_name"
    t.index ["sender_id"], name: "index_messages_on_sender_id", using: :btree
    t.index ["type"], name: "index_messages_on_type", using: :btree
    t.index ["uid"], name: "index_messages_on_uid", using: :btree
  end

  create_table "payola_affiliates", force: :cascade do |t|
    t.string   "code"
    t.string   "email"
    t.integer  "percent"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payola_coupons", force: :cascade do |t|
    t.string   "code"
    t.integer  "percent_off"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",      default: true
  end

  create_table "payola_sales", force: :cascade do |t|
    t.string   "email",                limit: 191
    t.string   "guid",                 limit: 191
    t.integer  "product_id"
    t.string   "product_type",         limit: 100
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
    t.string   "stripe_id"
    t.string   "stripe_token"
    t.string   "card_last4"
    t.date     "card_expiration"
    t.string   "card_type"
    t.text     "error"
    t.integer  "amount"
    t.integer  "fee_amount"
    t.integer  "coupon_id"
    t.boolean  "opt_in"
    t.integer  "download_count"
    t.integer  "affiliate_id"
    t.text     "customer_address"
    t.text     "business_address"
    t.string   "stripe_customer_id",   limit: 191
    t.string   "currency"
    t.text     "signed_custom_fields"
    t.integer  "owner_id"
    t.string   "owner_type",           limit: 100
    t.index ["coupon_id"], name: "index_payola_sales_on_coupon_id", using: :btree
    t.index ["email"], name: "index_payola_sales_on_email", using: :btree
    t.index ["guid"], name: "index_payola_sales_on_guid", using: :btree
    t.index ["owner_id", "owner_type"], name: "index_payola_sales_on_owner_id_and_owner_type", using: :btree
    t.index ["product_id", "product_type"], name: "index_payola_sales_on_product", using: :btree
    t.index ["stripe_customer_id"], name: "index_payola_sales_on_stripe_customer_id", using: :btree
  end

  create_table "payola_stripe_webhooks", force: :cascade do |t|
    t.string   "stripe_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payola_subscriptions", force: :cascade do |t|
    t.string   "plan_type"
    t.integer  "plan_id"
    t.datetime "start"
    t.string   "status"
    t.string   "owner_type"
    t.integer  "owner_id"
    t.string   "stripe_customer_id"
    t.boolean  "cancel_at_period_end"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "ended_at"
    t.datetime "trial_start"
    t.datetime "trial_end"
    t.datetime "canceled_at"
    t.integer  "quantity"
    t.string   "stripe_id"
    t.string   "stripe_token"
    t.string   "card_last4"
    t.date     "card_expiration"
    t.string   "card_type"
    t.text     "error"
    t.string   "state"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "currency"
    t.integer  "amount"
    t.string   "guid",                 limit: 191
    t.string   "stripe_status"
    t.integer  "affiliate_id"
    t.string   "coupon"
    t.text     "signed_custom_fields"
    t.text     "customer_address"
    t.text     "business_address"
    t.integer  "setup_fee"
    t.decimal  "tax_percent",                      precision: 4, scale: 2
    t.index ["guid"], name: "index_payola_subscriptions_on_guid", using: :btree
  end

  create_table "plans", force: :cascade do |t|
    t.string   "uid"
    t.string   "name"
    t.string   "stripe_id"
    t.string   "interval"
    t.integer  "amount"
    t.text     "features"
    t.string   "highlight"
    t.integer  "display_order"
    t.boolean  "enabled",       default: false, null: false
    t.boolean  "visible",       default: false, null: false
    t.boolean  "create_stripe", default: false, null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.jsonb    "config",        default: {},    null: false
    t.string   "key"
    t.index ["config"], name: "index_plans_on_config", using: :gin
    t.index ["create_stripe"], name: "index_plans_on_create_stripe", using: :btree
    t.index ["display_order"], name: "index_plans_on_display_order", using: :btree
    t.index ["enabled"], name: "index_plans_on_enabled", using: :btree
    t.index ["stripe_id"], name: "index_plans_on_stripe_id", using: :btree
    t.index ["uid"], name: "index_plans_on_uid", using: :btree
    t.index ["visible"], name: "index_plans_on_visible", using: :btree
  end

  create_table "registrations", force: :cascade do |t|
    t.string   "email",        limit: 255
    t.string   "locale",       limit: 8
    t.string   "country_code", limit: 2
    t.string   "ip_address",   limit: 255
    t.string   "first_name",   limit: 255
    t.string   "last_name",    limit: 255
    t.string   "time_zone",    limit: 255
    t.decimal  "lat",                      precision: 11, scale: 8
    t.decimal  "lng",                      precision: 11, scale: 8
    t.string   "address",      limit: 255
    t.string   "city",         limit: 255
    t.string   "postal_code",  limit: 255
    t.string   "region_code",  limit: 255
    t.string   "type",         limit: 255
    t.string   "uid",          limit: 255
    t.string   "referrer_uid", limit: 255
    t.boolean  "opt_in",                                            default: false,     null: false
    t.text     "fields"
    t.text     "user_data"
    t.string   "region_name",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aasm_state",   limit: 255,                          default: "pending", null: false
    t.datetime "accepted_at"
    t.datetime "declined_at"
    t.index ["aasm_state"], name: "index_registrations_on_aasm_state", using: :btree
    t.index ["email"], name: "index_registrations_on_email", unique: true, using: :btree
    t.index ["referrer_uid"], name: "index_registrations_on_referrer_uid", using: :btree
    t.index ["type"], name: "index_registrations_on_type", using: :btree
    t.index ["uid"], name: "index_registrations_on_uid", using: :btree
  end

  create_table "segments", force: :cascade do |t|
    t.integer  "document_id"
    t.integer  "track_id"
    t.integer  "ingest_id"
    t.integer  "chunk_id"
    t.integer  "position"
    t.string   "type",        limit: 255
    t.datetime "updated_at"
    t.datetime "created_at"
    t.boolean  "is_master",               default: false, null: false
    t.datetime "deleted_at"
    t.index ["chunk_id"], name: "index_segments_on_chunk_id", using: :btree
    t.index ["created_at"], name: "index_segments_on_created_at", using: :btree
    t.index ["deleted_at"], name: "index_segments_on_deleted_at", using: :btree
    t.index ["document_id"], name: "index_segments_on_document_id", using: :btree
    t.index ["ingest_id"], name: "index_segments_on_ingest_id", using: :btree
    t.index ["is_master"], name: "index_segments_on_is_master", using: :btree
    t.index ["position"], name: "index_segments_on_position", using: :btree
    t.index ["track_id"], name: "index_segments_on_track_id", using: :btree
    t.index ["type"], name: "index_segments_on_type", using: :btree
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type", limit: 255
    t.integer  "tagger_id"
    t.string   "tagger_type",   limit: 255
    t.string   "context",       limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context", using: :btree
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
    t.index ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy", using: :btree
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id", using: :btree
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type", using: :btree
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type", using: :btree
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id", using: :btree
  end

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255
    t.integer "taggings_count",             default: 0
    t.string  "slug",           limit: 255
    t.boolean "featured",                   default: false, null: false
    t.index ["featured"], name: "index_tags_on_featured", using: :btree
    t.index ["name"], name: "index_tags_on_name", unique: true, using: :btree
    t.index ["slug"], name: "index_tags_on_slug", using: :btree
  end

  create_table "tracks", force: :cascade do |t|
    t.string   "s3_url",               limit: 255
    t.string   "s3_mp3_url",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uid",                  limit: 255
    t.integer  "ingest_iteration"
    t.string   "s3_waveform_json_url", limit: 255
    t.string   "type",                 limit: 255
    t.decimal  "duration",                         precision: 15, scale: 3
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_tracks_on_deleted_at", using: :btree
    t.index ["duration"], name: "index_tracks_on_duration", using: :btree
    t.index ["end_at"], name: "index_tracks_on_end_at", using: :btree
    t.index ["ingest_iteration"], name: "index_tracks_on_ingest_iteration", using: :btree
    t.index ["start_at"], name: "index_tracks_on_start_at", using: :btree
    t.index ["type"], name: "index_tracks_on_type", using: :btree
    t.index ["uid"], name: "index_tracks_on_uid", using: :btree
  end

  create_table "turkee_imported_assignments", force: :cascade do |t|
    t.string   "assignment_id",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "turkee_task_id"
    t.string   "worker_id",      limit: 255
    t.integer  "result_id"
    t.index ["assignment_id"], name: "index_turkee_imported_assignments_on_assignment_id", unique: true, using: :btree
    t.index ["turkee_task_id"], name: "index_turkee_imported_assignments_on_turkee_task_id", using: :btree
  end

  create_table "turkee_studies", force: :cascade do |t|
    t.integer  "turkee_task_id"
    t.text     "feedback"
    t.string   "gold_response",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["turkee_task_id"], name: "index_turkee_studies_on_turkee_task_id", using: :btree
  end

  create_table "turkee_tasks", force: :cascade do |t|
    t.string   "hit_url",               limit: 255
    t.boolean  "sandbox"
    t.string   "task_type",             limit: 255
    t.text     "hit_title"
    t.text     "hit_description"
    t.string   "hit_id",                limit: 255
    t.decimal  "hit_reward",                        precision: 10, scale: 2
    t.integer  "hit_num_assignments"
    t.integer  "hit_lifetime"
    t.string   "form_url",              limit: 255
    t.integer  "completed_assignments",                                      default: 0
    t.boolean  "complete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hit_duration"
    t.integer  "expired"
  end

  create_table "uploads", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",        limit: 255
    t.string   "uid",         limit: 255
    t.datetime "recorded_at"
    t.integer  "user_id"
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_uploads_on_created_at", using: :btree
    t.index ["deleted_at"], name: "index_uploads_on_deleted_at", using: :btree
    t.index ["type"], name: "index_uploads_on_type", using: :btree
    t.index ["uid"], name: "index_uploads_on_uid", using: :btree
    t.index ["updated_at"], name: "index_uploads_on_updated_at", using: :btree
    t.index ["user_id"], name: "index_uploads_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255,                          default: "",    null: false
    t.string   "encrypted_password",     limit: 255,                          default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                               default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.integer  "failed_attempts",                                             default: 0,     null: false
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "lat",                                precision: 11, scale: 8
    t.decimal  "lng",                                precision: 11, scale: 8
    t.string   "time_zone",              limit: 255
    t.string   "address",                limit: 255
    t.string   "country_code",           limit: 2
    t.string   "city",                   limit: 255
    t.string   "postal_code",            limit: 255
    t.string   "region_code",            limit: 255
    t.string   "region_name",            limit: 255
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.string   "avatar_url",             limit: 255
    t.string   "css_hex_color",          limit: 255
    t.string   "initials",               limit: 255
    t.integer  "roles_mask"
    t.string   "username",               limit: 255
    t.string   "slug",                   limit: 255
    t.string   "uid",                    limit: 255
    t.text     "description"
    t.integer  "plan_id"
    t.jsonb    "properties",                                                  default: {},    null: false
    t.boolean  "approved",                                                    default: false, null: false
    t.string   "name"
    t.datetime "deleted_at"
    t.index ["approved"], name: "index_users_on_approved", using: :btree
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
    t.index ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["lat"], name: "index_users_on_lat", using: :btree
    t.index ["lng"], name: "index_users_on_lng", using: :btree
    t.index ["plan_id"], name: "index_users_on_plan_id", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["roles_mask"], name: "index_users_on_roles_mask", using: :btree
    t.index ["slug"], name: "index_users_on_slug", unique: true, using: :btree
    t.index ["uid"], name: "index_users_on_uid", using: :btree
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
    t.index ["username"], name: "index_users_on_username", unique: true, using: :btree
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255, null: false
    t.integer  "item_id",                null: false
    t.string   "event",      limit: 255, null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  end

end
