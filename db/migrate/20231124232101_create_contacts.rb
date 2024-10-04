class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.integer "source_id"
      t.integer "target_id"
      t.string "role", default: "contact", null: false, comment: "contact"
      t.string "status", default: "normal", null: false, comment: "normal | freezed"
      t.datetime "created_at", null: false
    end
  end
end
