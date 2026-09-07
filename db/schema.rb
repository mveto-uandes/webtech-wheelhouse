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

ActiveRecord::Schema[8.1].define(version: 2026_09_07_161526) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bikes", force: :cascade do |t|
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.string "make", null: false
    t.string "model", null: false
    t.string "serial_number", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_bikes_on_customer_id"
    t.index ["serial_number"], name: "index_bikes_on_serial_number", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.datetime "updated_at", null: false
  end

  create_table "employees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "method", null: false
    t.datetime "paid_at", null: false
    t.integer "repair_id", null: false
    t.datetime "updated_at", null: false
    t.index ["repair_id"], name: "index_payments_on_repair_id"
  end

  create_table "repair_line_items", force: :cascade do |t|
    t.decimal "charged_price", precision: 8, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "repair_id", null: false
    t.integer "service_id", null: false
    t.datetime "updated_at", null: false
    t.index ["repair_id"], name: "index_repair_line_items_on_repair_id"
    t.index ["service_id"], name: "index_repair_line_items_on_service_id"
  end

  create_table "repairs", force: :cascade do |t|
    t.integer "bike_id", null: false
    t.datetime "created_at", null: false
    t.text "diagnosis"
    t.datetime "handed_back_at"
    t.integer "mechanic_id"
    t.date "promised_on"
    t.text "reported_problem", null: false
    t.string "status", default: "received", null: false
    t.datetime "updated_at", null: false
    t.index ["bike_id"], name: "index_repairs_on_bike_id"
    t.index ["mechanic_id"], name: "index_repairs_on_mechanic_id"
  end

  create_table "services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.decimal "price", precision: 8, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_services_on_name", unique: true
  end
end
