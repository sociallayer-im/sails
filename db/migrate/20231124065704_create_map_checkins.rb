class CreateMapCheckins < ActiveRecord::Migration[7.1]
  def change
    create_table :map_checkins do |t|
      t.integer  "marker_id"
      t.integer  "profile_id"
      t.integer  "badgelet_id"
      t.string   "check_type"
      t.string   "content"
      t.string   "image_url"
      t.datetime "created_at", null: false
    end
  end
end
