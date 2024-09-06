class CreateMemberships < ActiveRecord::Migration[7.2]
  def change
    create_table :memberships do |t|
      t.integer "profile_id"
      t.integer "group_id"
      t.string "role", default: "member", null: false, comment: "member | operator | guardian | manager | owner"
      t.string "status", default: "normal", null: false, comment: "normal | freezed"
      t.jsonb "data"
      t.timestamps
    end
  end
end
