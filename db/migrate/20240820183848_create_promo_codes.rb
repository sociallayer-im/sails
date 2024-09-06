class CreatePromoCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :promo_codes do |t|
      t.string "selector", comment: "code | email | zupass | badge"
      t.string "label"
      t.string "code"
      t.string "receiver_address"
      t.string "discount_type", comment: "ratio | amount"
      t.integer "discount", comment: "0 to 100 for ratio, cent of dollar for amount"
      t.integer "event_id"
      t.integer "applicable_ticket_ids", array: true
      t.integer "ticket_item_ids", array: true
      t.datetime "expiry_time"
      t.integer "max_allowed_usages"
      t.integer "order_usage_count"
      t.boolean "removed"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
