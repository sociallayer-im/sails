class CreateMarkers < ActiveRecord::Migration[7.2]
  def change
    create_table :markers do |t|
      t.integer "owner_id"
      t.integer "group_id"
      t.string "marker_type", default: "site", null: false, comment: "site | event | share"
      t.string "category"
      t.string "pin_image_url"
      t.string "cover_image_url"
      t.string "title"
      t.text "about"
      t.string "link"
      t.string "status", default: "normal", null: false, comment: "normal | removed"
      t.string "location"
      t.string "formatted_address"
      t.text "location_viewport"
      t.decimal "geo_lat", precision: 10, scale: 6
      t.decimal "geo_lng", precision: 10, scale: 6
      t.datetime "start_time"
      t.datetime "end_time"
      t.jsonb "data"
      t.datetime "created_at", null: false
    end
  end
end
