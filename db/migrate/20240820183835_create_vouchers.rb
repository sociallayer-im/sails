class CreateVouchers < ActiveRecord::Migration[7.2]
  def change
    create_table :vouchers do |t|
      t.integer "sender_id"
      t.integer "badge_class_id"
      t.string "badge_title"
      t.string "badge_content"
      t.string "badge_image"
      t.string "badge_data", comment: "start_time, end_time, value, transferable, revocable"
      t.string "code"
      t.string "message"
      t.datetime "expires_at"
      t.integer "counter", default: 1
      t.integer "receiver_id"
      t.string "receiver_address"
      t.string "receiver_address_type", default: "id"
      t.datetime "claimed_at"
      t.boolean "claimed_by_server", default: false
      t.string "strategy", default: "code"
      t.integer "issued_amount"
      t.string "issued_token_ids", array: true
      t.string "minted_tx"
      t.string "minted_address"
      t.string "minted_ids", array: true
      t.datetime "created_at", null: false
      t.index ["sender_id"], name: "index_vouchers_on_sender_id"
    end
  end
end
