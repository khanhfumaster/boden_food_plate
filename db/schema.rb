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

ActiveRecord::Schema.define(version: 20150125012636) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "food_categories", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "food_diaries", force: true do |t|
    t.integer  "participant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pid"
    t.string   "visit"
  end

  create_table "foods", force: true do |t|
    t.string   "serving_size"
    t.float    "serving_weight"
    t.float    "energy"
    t.float    "protein"
    t.float    "total_fat"
    t.float    "saturated_fat"
    t.float    "cholesterol"
    t.float    "carbohydrate"
    t.float    "sugars"
    t.float    "dietary_fibre"
    t.float    "sodium"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "food_category_id"
    t.string   "name"
    t.float    "energy_c"
    t.string   "image_path"
    t.text     "swap_tip"
  end

  create_table "foods_meals", force: true do |t|
    t.integer "food_id"
    t.integer "meal_id"
  end

  create_table "meals", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "day"
    t.integer  "food_diary_id"
  end

  create_table "participants", force: true do |t|
    t.string   "pid"
    t.date     "date_of_birth"
    t.integer  "gender"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "group"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "role"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",      default: 0
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
