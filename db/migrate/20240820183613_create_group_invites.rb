class CreateGroupInvites < ActiveRecord::Migration[7.2]
  def change
    create_table :group_invites do |t|
      t.integer "sender_id"
      t.integer "receiver_id"
      t.integer "group_id"
      t.string "message"
      t.datetime "expires_at"
      t.integer "badge_class_id"
      t.string "role", default: "member"
      t.string "status", default: "sending"
      t.string "receiver_address_type", default: "id"
      t.string "receiver_address"
      t.jsonb "data"
      t.timestamps
    end
  end
end
