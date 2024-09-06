class CreateContacts < ActiveRecord::Migration[7.2]
  def change
    create_table "contacts", force: :cascade do |t|
      t.integer "source_id"
      t.integer "target_id"
      t.string "label"
      t.string "role", default: "contact", null: false, comment: "contact | follow"
      t.string "status", default: "normal", null: false, comment: "normal | freezed"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
