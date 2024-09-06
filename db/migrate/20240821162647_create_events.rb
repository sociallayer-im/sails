class CreateEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :events do |t|
      t.string "title"
      t.datetime "start_time"
      t.datetime "end_time"
      t.string "timezone"
      t.string "meeting_url"
      t.integer "venue_id"
      t.string "location"
      t.string "formatted_address"
      t.text "location_viewport"
      t.decimal "geo_lat", precision: 10, scale: 6
      t.decimal "geo_lng", precision: 10, scale: 6
      t.integer "owner_id"
      t.integer "group_id"
      t.string "cover_url"
      t.string "status", default: "published", null: false
      t.boolean "require_approval"
      t.text "content"
      t.string "tags", array: true
      t.integer "max_participant"
      t.integer "min_participant"
      t.integer "participants_count", default: 0
      t.integer "badge_class_id"
      t.integer "recurring_id"
      t.string "event_type", comment: "event"
      t.string "display", default: "normal", comment: "normal | hidden | pinned"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "external_url"
      t.text "notes"
      t.jsonb "extra"
    end
  end
end
