class CreateEventRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :event_roles do |t|
      t.integer "event_id"
      t.integer "profile_id"
      t.string "email"
      t.string "nickname"
      t.string "image_url"
      t.string "role"
      t.string "about"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
