class CreateTrackRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :track_roles do |t|
      t.integer "track_id"
      t.integer "profile_id"
      t.string "receiver_address"
      t.string "role", default: "member"
      t.timestamps
    end

    add_column :events, :track_id, :integer
  end
end
