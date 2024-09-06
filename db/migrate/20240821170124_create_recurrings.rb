class CreateRecurrings < ActiveRecord::Migration[7.2]
  def change
    create_table :recurrings do |t|
      t.datetime "start_time"
      t.datetime "end_time"
      t.string "interval"
      t.string "timezone"
      t.integer "event_count"
      t.jsonb "data"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
