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

ActiveRecord::Schema.define(version: 20140103032423) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "document_ingests", force: true do |t|
    t.integer  "upload_id"
    t.string   "locale",       limit: 5, default: "en-US", null: false
    t.integer  "privacy_mask",           default: 0,       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "document_id"
  end

  add_index "document_ingests", ["document_id"], name: "index_document_ingests_on_document_id", using: :btree
  add_index "document_ingests", ["locale"], name: "index_document_ingests_on_locale", using: :btree
  add_index "document_ingests", ["privacy_mask"], name: "index_document_ingests_on_privacy_mask", using: :btree
  add_index "document_ingests", ["upload_id"], name: "index_document_ingests_on_upload_id", using: :btree

  create_table "documents", force: true do |t|
    t.string   "title"
    t.string   "slug"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "documents", ["slug"], name: "index_documents_on_slug", using: :btree
  add_index "documents", ["title"], name: "index_documents_on_title", using: :btree

  create_table "uploads", force: true do |t|
    t.string   "file_name"
    t.string   "file_type"
    t.string   "file_size"
    t.string   "s3_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "uploads", ["file_name"], name: "index_uploads_on_file_name", using: :btree
  add_index "uploads", ["file_size"], name: "index_uploads_on_file_size", using: :btree
  add_index "uploads", ["file_type"], name: "index_uploads_on_file_type", using: :btree

end
