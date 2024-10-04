class CreateMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :memberships do |t|
      t.integer "profile_id"
      t.integer "target_id"
      t.string "role", default: "member", null: false, comment: "member | issuer | event_manager | guardian | manager | owner"
      t.string "status", default: "normal", null: false, comment: "normal | freezed"
      t.datetime "created_at"
    end
  end
end
