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

ActiveRecord::Schema[8.0].define(version: 2026_09_14_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bikes", force: :cascade do |t|
    t.string "serial_number", null: false
    t.string "make", null: false
    t.string "model", null: false
    t.string "color", null: false
    t.integer "customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_bikes_on_customer_id"
    t.index ["serial_number"], name: "index_bikes_on_serial_number", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mechanics", force: :cascade do |t|
    t.string "name", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "repair_line_items", force: :cascade do |t|
    t.integer "repair_order_id", null: false
    t.integer "service_id", null: false
    t.decimal "charged_price", precision: 8, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repair_order_id"], name: "index_repair_line_items_on_repair_order_id"
    t.index ["service_id"], name: "index_repair_line_items_on_service_id"
  end

  create_table "repair_orders", force: :cascade do |t|
    t.integer "bike_id", null: false
    t.integer "mechanic_id"
    t.string "status", default: "Dropped Off", null: false
    t.date "promised_on", null: false
    t.datetime "quoted_at"
    t.boolean "quote_accepted"
    t.datetime "completed_at"
    t.datetime "picked_up_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bike_id"], name: "index_repair_orders_on_bike_id"
    t.index ["mechanic_id"], name: "index_repair_orders_on_mechanic_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "default_price", precision: 8, scale: 2, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_services_on_name", unique: true
  end

  add_foreign_key "bikes", "customers"
  add_foreign_key "repair_line_items", "repair_orders"
  add_foreign_key "repair_line_items", "services"
  add_foreign_key "repair_orders", "bikes"
  add_foreign_key "repair_orders", "mechanics"
end
