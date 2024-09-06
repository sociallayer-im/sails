class CreateVenueOverrides < ActiveRecord::Migration[7.2]
  def change
    create_table :venue_overrides do |t|
      t.integer "venue_id"
      t.date "day"
      t.boolean "disabled"
      t.string "start_at"
      t.string "end_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
