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

ActiveRecord::Schema[8.1].define(version: 2026_10_08_160000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "checklist_answers", force: :cascade do |t|
    t.bigint "checklist_submission_id", null: false
    t.bigint "checklist_item_id", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_item_id"], name: "index_checklist_answers_on_checklist_item_id"
    t.index ["checklist_submission_id"], name: "index_checklist_answers_on_checklist_submission_id"
  end

  create_table "checklist_items", force: :cascade do |t|
    t.bigint "checklist_template_id", null: false
    t.string "label", null: false
    t.integer "item_type", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.boolean "required", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_template_id"], name: "index_checklist_items_on_checklist_template_id"
  end

  create_table "checklist_submissions", force: :cascade do |t|
    t.bigint "checklist_template_id", null: false
    t.bigint "vehicle_id", null: false
    t.bigint "user_id", null: false
    t.datetime "submitted_at"
    t.integer "status", default: 0, null: false
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id", null: false
    t.index ["checklist_template_id"], name: "index_checklist_submissions_on_checklist_template_id"
    t.index ["company_id"], name: "index_checklist_submissions_on_company_id"
    t.index ["user_id"], name: "index_checklist_submissions_on_user_id"
    t.index ["vehicle_id"], name: "index_checklist_submissions_on_vehicle_id"
  end

  create_table "checklist_templates", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_checklist_templates_on_company_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "rut"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "configuration", default: {}
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "vehicle_id"
    t.integer "category", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.date "date", null: false
    t.string "provider"
    t.text "description"
    t.boolean "restricted_access", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency", default: "CLP", null: false
    t.string "source_type"
    t.bigint "source_id"
    t.index ["company_id"], name: "index_expenses_on_company_id"
    t.index ["source_type", "source_id"], name: "index_expenses_on_source"
    t.index ["vehicle_id"], name: "index_expenses_on_vehicle_id"
  end

  create_table "fuel_fills", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "user_id", null: false
    t.bigint "company_id", null: false
    t.decimal "liters", precision: 10, scale: 2, null: false
    t.decimal "cost", precision: 10, scale: 2, null: false
    t.string "currency", default: "CLP", null: false
    t.integer "odometer", null: false
    t.date "date", null: false
    t.text "notes"
    t.decimal "km_per_liter", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_fuel_fills_on_company_id"
    t.index ["user_id"], name: "index_fuel_fills_on_user_id"
    t.index ["vehicle_id"], name: "index_fuel_fills_on_vehicle_id"
  end

  create_table "incidents", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "reporter_id", null: false
    t.bigint "company_id", null: false
    t.integer "status"
    t.integer "severity"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.index ["company_id"], name: "index_incidents_on_company_id"
    t.index ["reporter_id"], name: "index_incidents_on_reporter_id"
    t.index ["vehicle_id"], name: "index_incidents_on_vehicle_id"
  end

  create_table "maintenance_plans", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.text "description"
    t.integer "interval_km"
    t.integer "interval_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_maintenance_plans_on_company_id"
  end

  create_table "maintenance_task_templates", force: :cascade do |t|
    t.bigint "maintenance_plan_id", null: false
    t.string "description"
    t.integer "expected_duration_minutes"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["maintenance_plan_id"], name: "index_maintenance_task_templates_on_maintenance_plan_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "message", null: false
    t.datetime "read_at"
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "part_fitments", force: :cascade do |t|
    t.bigint "part_id", null: false
    t.bigint "vehicle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id", null: false
    t.index ["company_id"], name: "index_part_fitments_on_company_id"
    t.index ["part_id", "vehicle_id"], name: "index_part_fitments_on_part_id_and_vehicle_id", unique: true
    t.index ["part_id"], name: "index_part_fitments_on_part_id"
    t.index ["vehicle_id"], name: "index_part_fitments_on_vehicle_id"
  end

  create_table "part_quotes", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "part_id", null: false
    t.bigint "user_id"
    t.string "supplier", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.string "currency", default: "CLP", null: false
    t.date "quoted_on", null: false
    t.string "url"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_part_quotes_on_company_id"
    t.index ["part_id"], name: "index_part_quotes_on_part_id"
    t.index ["user_id"], name: "index_part_quotes_on_user_id"
  end

  create_table "parts", force: :cascade do |t|
    t.string "sku", null: false
    t.string "name", null: false
    t.string "unit_of_measure", null: false
    t.decimal "stock", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "cost", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency", default: "CLP", null: false
    t.index ["company_id", "sku"], name: "index_parts_on_company_id_and_sku", unique: true
    t.index ["company_id"], name: "index_parts_on_company_id"
  end

  create_table "password_reset_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "admin_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_password_reset_requests_on_admin_id"
    t.index ["user_id"], name: "index_password_reset_requests_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "endpoint", null: false
    t.string "p256dh", null: false
    t.string "auth", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "roadside_assistance_events", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "vehicle_id", null: false
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.text "description"
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_roadside_assistance_events_on_company_id"
    t.index ["user_id"], name: "index_roadside_assistance_events_on_user_id"
    t.index ["vehicle_id"], name: "index_roadside_assistance_events_on_vehicle_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "part_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.integer "movement_type", null: false
    t.string "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_id"], name: "index_stock_movements_on_part_id"
  end

  create_table "supply_request_lines", force: :cascade do |t|
    t.bigint "supply_request_id", null: false
    t.bigint "part_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_id"], name: "index_supply_request_lines_on_part_id"
    t.index ["supply_request_id"], name: "index_supply_request_lines_on_supply_request_id"
  end

  create_table "supply_requests", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id", null: false
    t.index ["company_id"], name: "index_supply_requests_on_company_id"
    t.index ["user_id"], name: "index_supply_requests_on_user_id"
    t.index ["vehicle_id"], name: "index_supply_requests_on_vehicle_id"
  end

  create_table "user_documents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "doc_type", null: false
    t.date "due_on", null: false
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_documents_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.bigint "company_id"
    t.boolean "force_password_change", default: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "vehicle_assignments", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "user_id", null: false
    t.date "started_on", null: false
    t.date "ended_on"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_vehicle_assignments_on_user_id"
    t.index ["vehicle_id"], name: "index_vehicle_assignments_on_vehicle_id"
  end

  create_table "vehicle_documents", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.integer "doc_type"
    t.date "due_on"
    t.text "notes"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vehicle_id"], name: "index_vehicle_documents_on_vehicle_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "plate"
    t.string "brand"
    t.string "model"
    t.integer "year"
    t.integer "status"
    t.integer "odometer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id", null: false
    t.index ["company_id"], name: "index_vehicles_on_company_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "work_order_part_usages", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.bigint "part_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_id"], name: "index_work_order_part_usages_on_part_id"
    t.index ["work_order_id"], name: "index_work_order_part_usages_on_work_order_id"
  end

  create_table "work_order_tasks", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.string "description", null: false
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_order_id"], name: "index_work_order_tasks_on_work_order_id"
  end

  create_table "work_orders", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "vehicle_id", null: false
    t.bigint "maintenance_plan_id"
    t.integer "status", default: 0, null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.bigint "mechanic_id"
    t.integer "odometer_at_maintenance"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_work_orders_on_company_id"
    t.index ["maintenance_plan_id"], name: "index_work_orders_on_maintenance_plan_id"
    t.index ["mechanic_id"], name: "index_work_orders_on_mechanic_id"
    t.index ["vehicle_id"], name: "index_work_orders_on_vehicle_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "checklist_answers", "checklist_items"
  add_foreign_key "checklist_answers", "checklist_submissions"
  add_foreign_key "checklist_items", "checklist_templates"
  add_foreign_key "checklist_submissions", "checklist_templates"
  add_foreign_key "checklist_submissions", "companies"
  add_foreign_key "checklist_submissions", "users"
  add_foreign_key "checklist_submissions", "vehicles"
  add_foreign_key "checklist_templates", "companies"
  add_foreign_key "expenses", "companies"
  add_foreign_key "expenses", "vehicles"
  add_foreign_key "fuel_fills", "companies"
  add_foreign_key "fuel_fills", "users"
  add_foreign_key "fuel_fills", "vehicles"
  add_foreign_key "incidents", "companies"
  add_foreign_key "incidents", "users", column: "reporter_id"
  add_foreign_key "incidents", "vehicles"
  add_foreign_key "maintenance_plans", "companies"
  add_foreign_key "maintenance_task_templates", "maintenance_plans"
  add_foreign_key "notifications", "users"
  add_foreign_key "part_fitments", "companies"
  add_foreign_key "part_fitments", "parts"
  add_foreign_key "part_fitments", "vehicles"
  add_foreign_key "part_quotes", "companies"
  add_foreign_key "part_quotes", "parts"
  add_foreign_key "part_quotes", "users"
  add_foreign_key "parts", "companies"
  add_foreign_key "password_reset_requests", "users"
  add_foreign_key "password_reset_requests", "users", column: "admin_id"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "roadside_assistance_events", "companies"
  add_foreign_key "roadside_assistance_events", "users"
  add_foreign_key "roadside_assistance_events", "vehicles"
  add_foreign_key "stock_movements", "parts"
  add_foreign_key "supply_request_lines", "parts"
  add_foreign_key "supply_request_lines", "supply_requests"
  add_foreign_key "supply_requests", "companies"
  add_foreign_key "supply_requests", "users"
  add_foreign_key "supply_requests", "vehicles"
  add_foreign_key "user_documents", "users"
  add_foreign_key "users", "companies"
  add_foreign_key "vehicle_assignments", "users"
  add_foreign_key "vehicle_assignments", "vehicles"
  add_foreign_key "vehicle_documents", "vehicles"
  add_foreign_key "vehicles", "companies"
  add_foreign_key "work_order_part_usages", "parts"
  add_foreign_key "work_order_part_usages", "work_orders"
  add_foreign_key "work_order_tasks", "work_orders"
  add_foreign_key "work_orders", "companies"
  add_foreign_key "work_orders", "maintenance_plans"
  add_foreign_key "work_orders", "users", column: "mechanic_id"
  add_foreign_key "work_orders", "vehicles"
end
