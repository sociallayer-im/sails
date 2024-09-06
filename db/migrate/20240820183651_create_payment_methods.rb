class CreatePaymentMethods < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_methods do |t|
      t.string "item_type"
      t.integer "item_id"
      t.string "chain"
      t.string "kind", default: "crypto", null: false, comment: "crypto | fiat | credit | free"
      t.string "token_name"
      t.string "token_address"
      t.string "receiver_address"
      t.decimal "price", precision: 40
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
