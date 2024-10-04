class CreateEstores < ActiveRecord::Migration[7.1]
  def change
    create_table :estores do |t|
      t.string "title"
      t.integer "group_id"
      t.integer "owner_id"
      t.string "status", default: "normal", null: false, comment: "draft | normal | closed"
      t.string "image_url"
      t.string "background_url"
      t.text "content"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
