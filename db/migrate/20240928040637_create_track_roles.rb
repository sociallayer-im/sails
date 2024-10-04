class CreateTrackRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :track_roles do |t|
      t.integer "group_id"
      t.integer "track_id"
      t.integer "profile_id"
      t.string "receiver_address"
      t.string "role", default: "member"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
