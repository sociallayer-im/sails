class CreateTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :tickets do |t|
      t.string "title"
      t.string "content"
      t.string "ticket_type", default: "event", comment: "event | group"
      t.integer "group_id"
      t.integer "event_id"
      t.integer "check_badge_class_id"
      t.integer "quantity"
      t.datetime "end_time"
      t.boolean "need_approval"
      t.string "status", default: "normal"
      t.datetime "created_at", null: false
      t.string "zupass_event_id"
      t.string "zupass_product_id"
      t.string "zupass_product_name"
      t.date "start_date"
      t.date "end_date"
      t.date "days_allowed", array: true
      t.string "tracks_allowed", array: true
    end
  end
end
