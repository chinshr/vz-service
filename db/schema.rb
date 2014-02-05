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

ActiveRecord::Schema.define(version: 20140205022913) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "documents", force: true do |t|
    t.string   "title"
    t.string   "slug",                                     null: false
    t.text     "description"
    t.integer  "privacy_mask",           default: 0,       null: false
    t.string   "locale",       limit: 5, default: "en-US", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "content"
  end

  add_index "documents", ["created_at"], name: "index_documents_on_created_at", using: :btree
  add_index "documents", ["locale"], name: "index_documents_on_locale", using: :btree
  add_index "documents", ["privacy_mask"], name: "index_documents_on_privacy_mask", using: :btree
  add_index "documents", ["slug"], name: "index_documents_on_slug", unique: true, using: :btree
  add_index "documents", ["title"], name: "index_documents_on_title", using: :btree
  add_index "documents", ["updated_at"], name: "index_documents_on_updated_at", using: :btree

  create_table "ingest_audio_segments", force: true do |t|
    t.integer  "ingest_id"
    t.integer  "offset"
    t.decimal  "duration",   precision: 9, scale: 3
    t.decimal  "start_time", precision: 9, scale: 3
    t.decimal  "end_time",   precision: 9, scale: 3
    t.text     "response"
    t.string   "best_text"
    t.float    "best_score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ingest_audio_segments", ["ingest_id"], name: "index_ingest_audio_segments_on_ingest_id", using: :btree
  add_index "ingest_audio_segments", ["offset"], name: "index_ingest_audio_segments_on_offset", using: :btree

  create_table "ingests", force: true do |t|
    t.integer  "upload_id"
    t.integer  "ingestable_id"
    t.string   "ingestable_type"
    t.string   "type"
    t.string   "aasm_state",      default: "created", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "reset_at"
    t.datetime "removed_at"
    t.datetime "finished_at"
    t.float    "progress",        default: 0.0,       null: false
    t.text     "messages"
    t.string   "stage"
    t.string   "s3_url"
    t.integer  "iteration",       default: 0,         null: false
    t.boolean  "busy",            default: false,     null: false
    t.datetime "restarted_at"
  end

  add_index "ingests", ["aasm_state"], name: "index_ingests_on_aasm_state", using: :btree
  add_index "ingests", ["created_at"], name: "index_ingests_on_created_at", using: :btree
  add_index "ingests", ["finished_at"], name: "index_ingests_on_finished_at", using: :btree
  add_index "ingests", ["ingestable_id", "ingestable_type"], name: "index_ingests_on_ingestable_id_and_ingestable_type", using: :btree
  add_index "ingests", ["iteration"], name: "index_ingests_on_iteration", using: :btree
  add_index "ingests", ["removed_at"], name: "index_ingests_on_removed_at", using: :btree
  add_index "ingests", ["reset_at"], name: "index_ingests_on_reset_at", using: :btree
  add_index "ingests", ["stage"], name: "index_ingests_on_stage", using: :btree
  add_index "ingests", ["started_at"], name: "index_ingests_on_started_at", using: :btree
  add_index "ingests", ["stopped_at"], name: "index_ingests_on_stopped_at", using: :btree
  add_index "ingests", ["type"], name: "index_ingests_on_type", using: :btree
  add_index "ingests", ["updated_at"], name: "index_ingests_on_updated_at", using: :btree
  add_index "ingests", ["upload_id"], name: "index_ingests_on_upload_id", using: :btree

  create_table "sessions", force: true do |t|
    t.string   "uid"
    t.string   "ip"
    t.string   "user_agent"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["uid"], name: "index_sessions_on_uid", using: :btree

  create_table "uploads", force: true do |t|
    t.string   "file_name"
    t.string   "file_type"
    t.integer  "file_size"
    t.string   "s3_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.integer  "session_id"
  end

  add_index "uploads", ["created_at"], name: "index_uploads_on_created_at", using: :btree
  add_index "uploads", ["file_name"], name: "index_uploads_on_file_name", using: :btree
  add_index "uploads", ["file_size"], name: "index_uploads_on_file_size", using: :btree
  add_index "uploads", ["file_type"], name: "index_uploads_on_file_type", using: :btree
  add_index "uploads", ["session_id"], name: "index_uploads_on_session_id", using: :btree
  add_index "uploads", ["type"], name: "index_uploads_on_type", using: :btree
  add_index "uploads", ["updated_at"], name: "index_uploads_on_updated_at", using: :btree

end
