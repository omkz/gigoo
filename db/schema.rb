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

ActiveRecord::Schema[8.1].define(version: 2026_08_28_040000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "client_profiles", force: :cascade do |t|
    t.text "bio"
    t.string "company_name"
    t.datetime "created_at", null: false
    t.string "location"
    t.boolean "payment_verified", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_client_profiles_on_user_id", unique: true
  end

  create_table "contracts", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.bigint "client_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "freelancer_id", null: false
    t.bigint "job_id", null: false
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_contracts_on_client_id"
    t.index ["freelancer_id"], name: "index_contracts_on_freelancer_id"
    t.index ["job_id"], name: "index_contracts_on_job_id"
  end

  create_table "freelancer_profiles", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.integer "hourly_rate_cents"
    t.string "location"
    t.string "skills", default: [], null: false, array: true
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_freelancer_profiles_on_user_id", unique: true
  end

  create_table "jobs", force: :cascade do |t|
    t.integer "budget_cents", null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "skills", default: [], null: false, array: true
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_jobs_on_client_id"
  end

  create_table "proposals", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.bigint "freelancer_id", null: false
    t.bigint "job_id", null: false
    t.text "message", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["freelancer_id"], name: "index_proposals_on_freelancer_id"
    t.index ["job_id", "freelancer_id"], name: "index_proposals_on_job_id_and_freelancer_id", unique: true
    t.index ["job_id"], name: "index_proposals_on_job_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "body"
    t.bigint "contract_id", null: false
    t.datetime "created_at", null: false
    t.integer "rating", null: false
    t.bigint "reviewee_id", null: false
    t.bigint "reviewer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id", "reviewer_id"], name: "index_reviews_on_contract_id_and_reviewer_id", unique: true
    t.index ["contract_id"], name: "index_reviews_on_contract_id"
    t.index ["reviewee_id"], name: "index_reviews_on_reviewee_id"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shortlists", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.bigint "freelancer_id", null: false
    t.bigint "job_id", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_shortlists_on_client_id"
    t.index ["freelancer_id"], name: "index_shortlists_on_freelancer_id"
    t.index ["job_id", "client_id", "freelancer_id"], name: "index_shortlists_on_job_id_and_client_id_and_freelancer_id", unique: true
    t.index ["job_id"], name: "index_shortlists_on_job_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "client_profiles", "users"
  add_foreign_key "contracts", "jobs"
  add_foreign_key "contracts", "users", column: "client_id"
  add_foreign_key "contracts", "users", column: "freelancer_id"
  add_foreign_key "freelancer_profiles", "users"
  add_foreign_key "jobs", "users", column: "client_id"
  add_foreign_key "proposals", "jobs"
  add_foreign_key "proposals", "users", column: "freelancer_id"
  add_foreign_key "reviews", "contracts"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "shortlists", "jobs"
  add_foreign_key "shortlists", "users", column: "client_id"
  add_foreign_key "shortlists", "users", column: "freelancer_id"
end
