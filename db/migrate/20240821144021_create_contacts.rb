class CreateContacts < ActiveRecord::Migration[7.2]
  def change
    create_table "contacts", force: :cascade do |t|
      t.integer "source_id"
      t.integer "target_id"
      t.string "label"
      t.string "role", default: "contact", null: false, comment: "contact | follower"
      t.string "status", default: "active", null: false, comment: "active | freezed"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
