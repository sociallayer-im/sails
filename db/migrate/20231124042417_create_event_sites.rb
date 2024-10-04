class CreateEventSites < ActiveRecord::Migration[7.1]
  def change
    create_table :event_sites do |t|
      t.string "title"
      t.string "location"
      t.string "about"
      t.integer "group_id"
      t.integer "owner_id"
      t.string  "formatted_address"
      t.text    "location_viewport"
      t.decimal "geo_lat", precision: 10, scale: 6
      t.decimal "geo_lng", precision: 10, scale: 6
      t.datetime "created_at", null: false
    end
  end
end
