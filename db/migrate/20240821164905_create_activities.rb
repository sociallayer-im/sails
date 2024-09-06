class CreateActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :activities do |t|
      t.integer "item_type"
      t.integer "item_class_id"
      t.integer "item_id"
      t.integer "initiator_id"
      t.integer "target_type"
      t.integer "target_id"
      t.string "context"
      t.string "action"
      t.string "data"
      t.string "memo"
      t.integer "receiver_id"
      t.string "receiver_type", default: "id"
      t.string "receiver_address"
      t.boolean "has_read", default: false
      t.datetime "created_at", null: false
    end
  end
end
