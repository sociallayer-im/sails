class CreateVenues < ActiveRecord::Migration[7.2]
  def change
    create_table :venues do |t|
      t.string "title"
      t.string "location"
      t.text "about"
      t.integer "group_id"
      t.integer "owner_id"
      t.string "formatted_address"
      t.text "location_viewport"
      t.decimal "geo_lat", precision: 10, scale: 6
      t.decimal "geo_lng", precision: 10, scale: 6
      t.datetime "created_at", null: false
      t.date "start_date"
      t.date "end_date"
      t.string "link"
      t.integer "capacity"
      t.boolean "require_approval", default: false
      t.string "tags", array: true
      t.string "visibility", comment: "all | manager | none"
    end
  end
end
