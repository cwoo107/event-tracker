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

ActiveRecord::Schema[8.1].define(version: 2026_08_26_184340) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

  create_table "account_memberships", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id", "user_id"], name: "index_account_memberships_on_account_id_and_user_id", unique: true
    t.index ["account_id"], name: "index_account_memberships_on_account_id"
    t.index ["user_id"], name: "index_account_memberships_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "office_address"
    t.string "office_city"
    t.geography "office_location", limit: {srid: 4326, type: "st_point", geographic: true}
    t.string "office_state", default: "CA"
    t.string "office_zip"
    t.datetime "updated_at", null: false
  end

  create_table "activities", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id"
    t.datetime "created_at", null: false
    t.jsonb "meta", default: {}, null: false
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.index ["actor_id"], name: "index_activities_on_actor_id"
    t.index ["subject_type", "subject_id", "created_at"], name: "index_activities_on_subject_type_and_subject_id_and_created_at"
    t.index ["subject_type", "subject_id"], name: "index_activities_on_subject"
  end

  create_table "assignment_rules", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "key", null: false
    t.decimal "threshold", precision: 8, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["account_id", "key"], name: "index_assignment_rules_on_account_id_and_key", unique: true
    t.index ["account_id"], name: "index_assignment_rules_on_account_id"
    t.index ["updated_by_id"], name: "index_assignment_rules_on_updated_by_id"
  end

  create_table "assignment_settings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.integer "weekly_target", default: 2, null: false
    t.integer "work_weeks_per_year", default: 46, null: false
    t.index ["account_id"], name: "index_assignment_settings_on_account_id", unique: true
    t.index ["updated_by_id"], name: "index_assignment_settings_on_updated_by_id"
  end

  create_table "assignments", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "assigned_by_id"
    t.integer "assignment_method", default: 0, null: false
    t.integer "assignment_status", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "liaison_id", null: false
    t.datetime "reminder_sent_at"
    t.decimal "score", precision: 6, scale: 2
    t.jsonb "score_breakdown", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_by_id"], name: "index_assignments_on_assigned_by_id"
    t.index ["event_id", "active"], name: "index_assignments_on_event_id_and_active"
    t.index ["event_id", "created_at"], name: "index_assignments_on_event_id_and_created_at"
    t.index ["event_id"], name: "index_assignments_on_event_id"
    t.index ["liaison_id", "active"], name: "index_assignments_on_liaison_id_and_active"
    t.index ["liaison_id"], name: "index_assignments_on_liaison_id"
  end

  create_table "event_material_items", force: :cascade do |t|
    t.boolean "checked", default: false, null: false
    t.datetime "checked_at"
    t.bigint "checked_by_id"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "material_item_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["checked_by_id"], name: "index_event_material_items_on_checked_by_id"
    t.index ["event_id", "material_item_id"], name: "index_event_material_items_on_event_and_material", unique: true
    t.index ["event_id"], name: "index_event_material_items_on_event_id"
    t.index ["material_item_id"], name: "index_event_material_items_on_material_item_id"
  end

  create_table "event_types", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_event_types_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_event_types_on_account_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "address"
    t.string "audience"
    t.string "city"
    t.string "county"
    t.datetime "created_at", null: false
    t.integer "drive_distance_meters"
    t.jsonb "drive_route_geometry"
    t.integer "drive_time_seconds"
    t.datetime "ends_at", null: false
    t.integer "estimated_attendees"
    t.bigint "event_type_id", null: false
    t.geography "location", limit: {srid: 4326, type: "st_point", geographic: true}, null: false
    t.boolean "overnight_approved", default: false, null: false
    t.integer "prep_minutes", default: 30, null: false
    t.string "requester_email"
    t.string "requester_name"
    t.string "requester_organization"
    t.string "requester_phone"
    t.integer "source", default: 2, null: false
    t.datetime "starts_at", null: false
    t.string "state", default: "CA"
    t.integer "status", default: 0, null: false
    t.integer "teardown_minutes", default: 30, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "venue_name"
    t.string "zip"
    t.index ["account_id"], name: "index_events_on_account_id"
    t.index ["county"], name: "index_events_on_county"
    t.index ["event_type_id"], name: "index_events_on_event_type_id"
    t.index ["location"], name: "index_events_on_location", using: :gist
    t.index ["starts_at"], name: "index_events_on_starts_at"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "liaison_load_holds", force: :cascade do |t|
    t.boolean "block_weekends", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.date "ends_on", null: false
    t.bigint "liaison_id", null: false
    t.integer "max_drive_minutes"
    t.string "reason"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_liaison_load_holds_on_created_by_id"
    t.index ["liaison_id", "ends_on"], name: "index_liaison_load_holds_on_liaison_id_and_ends_on"
    t.index ["liaison_id"], name: "index_liaison_load_holds_on_liaison_id"
  end

  create_table "liaison_time_offs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.bigint "liaison_id", null: false
    t.string "reason"
    t.date "starts_on", null: false
    t.datetime "updated_at", null: false
    t.index ["liaison_id", "starts_on", "ends_on"], name: "idx_on_liaison_id_starts_on_ends_on_078e4f2a0a"
    t.index ["liaison_id"], name: "index_liaison_time_offs_on_liaison_id"
  end

  create_table "liaisons", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.string "home_city"
    t.string "region"
    t.string "skills", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id", "color"], name: "index_liaisons_on_account_id_and_color", unique: true
    t.index ["account_id"], name: "index_liaisons_on_account_id"
    t.index ["user_id"], name: "index_liaisons_on_user_id", unique: true
  end

  create_table "material_items", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_material_items_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_material_items_on_account_id"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_notes_on_author_id"
    t.index ["event_id", "created_at"], name: "index_notes_on_event_id_and_created_at"
    t.index ["event_id"], name: "index_notes_on_event_id"
  end

  create_table "risk_thresholds", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "key", null: false
    t.decimal "multiplier", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["account_id", "key"], name: "index_risk_thresholds_on_account_id_and_key", unique: true
    t.index ["account_id"], name: "index_risk_thresholds_on_account_id"
    t.index ["updated_by_id"], name: "index_risk_thresholds_on_updated_by_id"
  end

  create_table "scoring_weights", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "criterion", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.decimal "weight", precision: 5, scale: 2, null: false
    t.index ["account_id", "criterion"], name: "index_scoring_weights_on_account_id_and_criterion", unique: true
    t.index ["account_id"], name: "index_scoring_weights_on_account_id"
    t.index ["updated_by_id"], name: "index_scoring_weights_on_updated_by_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_sessions_on_account_id"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "job_title"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "account_memberships", "accounts"
  add_foreign_key "account_memberships", "users"
  add_foreign_key "activities", "users", column: "actor_id"
  add_foreign_key "assignment_rules", "accounts"
  add_foreign_key "assignment_rules", "users", column: "updated_by_id"
  add_foreign_key "assignment_settings", "accounts"
  add_foreign_key "assignment_settings", "users", column: "updated_by_id"
  add_foreign_key "assignments", "events"
  add_foreign_key "assignments", "liaisons"
  add_foreign_key "assignments", "users", column: "assigned_by_id"
  add_foreign_key "event_material_items", "events"
  add_foreign_key "event_material_items", "material_items"
  add_foreign_key "event_material_items", "users", column: "checked_by_id"
  add_foreign_key "event_types", "accounts"
  add_foreign_key "events", "accounts"
  add_foreign_key "events", "event_types"
  add_foreign_key "liaison_load_holds", "liaisons"
  add_foreign_key "liaison_load_holds", "users", column: "created_by_id"
  add_foreign_key "liaison_time_offs", "liaisons"
  add_foreign_key "liaisons", "accounts"
  add_foreign_key "liaisons", "users"
  add_foreign_key "material_items", "accounts"
  add_foreign_key "notes", "events"
  add_foreign_key "notes", "users", column: "author_id"
  add_foreign_key "risk_thresholds", "accounts"
  add_foreign_key "risk_thresholds", "users", column: "updated_by_id"
  add_foreign_key "scoring_weights", "accounts"
  add_foreign_key "scoring_weights", "users", column: "updated_by_id"
  add_foreign_key "sessions", "accounts"
  add_foreign_key "sessions", "users"
end
