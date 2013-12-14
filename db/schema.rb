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

ActiveRecord::Schema.define(version: 20131214182436) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "document_ingests", force: true do |t|
    t.string   "file_name"
    t.string   "name"
    t.string   "locale",       limit: 5, default: "en-US", null: false
    t.integer  "privacy_mask",           default: 0,       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "document_ingests", ["file_name"], name: "index_document_ingests_on_file_name", using: :btree
  add_index "document_ingests", ["locale"], name: "index_document_ingests_on_locale", using: :btree
  add_index "document_ingests", ["name"], name: "index_document_ingests_on_name", using: :btree

end
