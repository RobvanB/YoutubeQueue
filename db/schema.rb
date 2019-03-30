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

ActiveRecord::Schema.define(version: 2019_03_23_225627) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "videos", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.string "subscription"
    t.string "channel"
    t.boolean "watched"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "published"
    t.index ["channel", "title"], name: "index_videos_on_channel_and_title", unique: true
  end

  create_table "ytq_params", force: :cascade do |t|
    t.string "last_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
