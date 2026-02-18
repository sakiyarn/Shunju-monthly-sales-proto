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

ActiveRecord::Schema[7.2].define(version: 2026_02_18_000100) do
  create_table "billing_adjustments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "project_id"
    t.date "original_month"
    t.date "applied_month"
    t.decimal "adjustment_amount", precision: 15, scale: 2
    t.string "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_billing_adjustments_on_project_id"
    t.index ["user_id", "project_id", "original_month", "applied_month"], name: "idx_billing_adjustments_lookup"
    t.index ["user_id"], name: "index_billing_adjustments_on_user_id"
  end

  create_table "billing_work_logs", force: :cascade do |t|
    t.integer "user_id"
    t.integer "project_id"
    t.date "work_month", null: false
    t.decimal "billed_hours", precision: 15, scale: 2
    t.decimal "billing_rate", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_billing_work_logs_on_project_id"
    t.index ["user_id", "project_id", "work_month"], name: "idx_on_user_id_project_id_work_month_8e05b15d84", unique: true
    t.index ["user_id"], name: "index_billing_work_logs_on_user_id"
  end

  create_table "directed_expense_assignments", force: :cascade do |t|
    t.integer "directed_expense_id"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["directed_expense_id", "project_id"], name: "idx_directed_expense_project", unique: true
    t.index ["directed_expense_id"], name: "index_directed_expense_assignments_on_directed_expense_id"
    t.index ["project_id"], name: "index_directed_expense_assignments_on_project_id"
  end

  create_table "directed_expenses", force: :cascade do |t|
    t.date "work_month", null: false
    t.decimal "amount", precision: 15, scale: 2
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "executive_adjustments", force: :cascade do |t|
    t.date "work_month", null: false
    t.decimal "executive_salary", precision: 15, scale: 2
    t.decimal "executive_welfare", precision: 15, scale: 2
    t.decimal "executive_bonus", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_month"], name: "index_executive_adjustments_on_work_month"
  end

  create_table "monthly_accounting_data", force: :cascade do |t|
    t.date "work_month", null: false
    t.decimal "sales", precision: 15, scale: 2
    t.decimal "personnel_cost", precision: 15, scale: 2
    t.decimal "selling_general_admin_cost", precision: 15, scale: 2
    t.decimal "accounting_operating_profit", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_month"], name: "index_monthly_accounting_data_on_work_month", unique: true
  end

  create_table "monthly_business_days", force: :cascade do |t|
    t.date "work_month", null: false
    t.integer "business_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_month"], name: "index_monthly_business_days_on_work_month", unique: true
  end

  create_table "project_members", force: :cascade do |t|
    t.integer "project_id"
    t.integer "user_id"
    t.decimal "default_billing_rate", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "user_id"], name: "index_project_members_on_project_id_and_user_id", unique: true
    t.index ["project_id"], name: "index_project_members_on_project_id"
    t.index ["user_id"], name: "index_project_members_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.string "client_name"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "display_order", default: 9999, null: false
    t.index ["display_order"], name: "index_projects_on_display_order"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.integer "display_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "staff_monthly_results", force: :cascade do |t|
    t.integer "user_id"
    t.date "work_month", null: false
    t.decimal "salary", precision: 15, scale: 2
    t.decimal "legal_welfare", precision: 15, scale: 2
    t.decimal "welfare", precision: 15, scale: 2
    t.decimal "bonus", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "work_month"], name: "index_staff_monthly_results_on_user_id_and_work_month", unique: true
    t.index ["user_id"], name: "index_staff_monthly_results_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "system_role", default: "member", null: false
    t.integer "role_id"
    t.string "display_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_active", default: true, null: false
    t.integer "display_order", default: 9999, null: false
    t.index ["display_order"], name: "index_users_on_display_order"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_active"], name: "index_users_on_is_active"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "billing_adjustments", "projects"
  add_foreign_key "billing_adjustments", "users"
  add_foreign_key "billing_work_logs", "projects"
  add_foreign_key "billing_work_logs", "users"
  add_foreign_key "directed_expense_assignments", "directed_expenses"
  add_foreign_key "directed_expense_assignments", "projects"
  add_foreign_key "project_members", "projects"
  add_foreign_key "project_members", "users"
  add_foreign_key "staff_monthly_results", "users"
  add_foreign_key "users", "roles"
end
