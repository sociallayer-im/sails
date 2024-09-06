class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.string  "item_type"
      t.integer "item_id"
      t.string "comment_type"
      t.integer "profile_id"
      t.integer "badge_id"
      t.string "status", default: "normal"
      t.string "title"
      t.text  "content"
      t.string "icon_url"
      t.string "content_type", default: "text/plain"
      t.integer "reply_parent_id"
      t.integer "edit_parent_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
