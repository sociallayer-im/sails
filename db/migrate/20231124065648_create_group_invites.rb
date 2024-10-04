class CreateGroupInvites < ActiveRecord::Migration[7.1]
  def change
    create_table :group_invites do |t|
    t.integer "sender_id"
    t.integer "receiver_id"
    t.integer "group_id"
    t.string "message"
    t.datetime "expires_at"
    t.integer "badge_id"
    t.integer "badgelet_id"
    t.string "role", default: "member"
    t.string "status", default: "sending", null: false, comment: "sending | accepted | cancel | revoked"
    t.boolean "accepted", default: false
    t.datetime "created_at", null: false
    end
  end
end
