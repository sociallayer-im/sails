class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.integer "estore_id"
      t.integer "profile_id"
      t.integer "amount"
      t.integer "payment_point_class_id"
      t.integer "payment_badge_id"
      t.string  "memo"
      t.string  "status", default: "normal", null: false, comment: "normal | cancel"
      t.string  "pay_status", default: "pending", comment: "pending | success | cancel"
      t.string  "delivery_code"
      t.string  "delivery_status", default: "success", comment: "pending | success | failed | cancel"
      t.datetime "created_at", null: false
    end
  end
end
