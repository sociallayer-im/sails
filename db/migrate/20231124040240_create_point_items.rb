class CreatePointItems < ActiveRecord::Migration[7.1]
  def change
    create_table :point_items do |t|
      t.integer "point_class_id"
      t.integer "sender_id"
      t.integer "owner_id"
      t.integer "value", default: 0
      t.string  "status", default: "pending", null: false, comment: "pending | accepted | rejected | revoked"
      t.datetime "created_at", null: false
    end
  end
end
