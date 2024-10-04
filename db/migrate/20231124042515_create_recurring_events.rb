class CreateRecurringEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :recurring_events do |t|
      t.datetime "start_time"
      t.datetime "end_time"
      t.string "interval"
      t.integer "event_count"
      t.string "timezone"
    end
  end
end
