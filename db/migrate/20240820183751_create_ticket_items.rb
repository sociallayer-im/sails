class CreateTicketItems < ActiveRecord::Migration[7.2]
  def change
    create_table :ticket_items do |t|
      t.integer "profile_id"
      t.integer "ticket_id"
      t.integer "event_id"
      t.string "chain"
      t.string "txhash"
      t.string "status"
      t.string "discount_value"
      t.string "discount_data"
      t.string "order_number"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "ticket_type", default: "event", comment: "event | group"
      t.string "auth_type", comment: "free | payment | zupass | badge | invite"
      t.integer "group_id"
      t.integer "participant_id"
      t.integer "payment_method_id"
      t.decimal "amount", precision: 40
      t.decimal "original_price", precision: 40
      t.integer "token_address"
      t.integer "receiver_address"
    end
  end
end
