class CreatePointTransfers < ActiveRecord::Migration[7.2]
  def change
    create_table :point_transfers do |t|
      t.integer "point_class_id"
      t.integer "sender_id"
      t.integer "receiver_id"
      t.integer "value", default: 0
      t.string "status", default: "pending", null: false, comment: "pending | accepted | rejected | revoked"
      t.timestamps
    end
  end
end
