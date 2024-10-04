class RenameBadgeletTable < ActiveRecord::Migration[7.1]
  def up
    remove_foreign_key "group_invites", "badgelets"
    remove_foreign_key "map_checkins", "badgelets"
    remove_foreign_key "participants", "badgelets"
    remove_index :badgelets, :creator_id, name: "index_badgelets_on_creator_id"
    remove_index :badgelets, :owner_id, name: "index_badgelets_on_owner_id"
    rename_column :group_invites, :badgelet_id, :badge_id
    rename_column :map_checkins, :badgelet_id, :badge_id
    rename_column :participants, :badgelet_id, :badge_id
    rename_table :badgelets, :badges
  end

  def down
    rename_table :badges, :badgelets
    rename_column :group_invites, :badge_id, :badgelet_id
    rename_column :map_checkins, :badge_id, :badgelet_id
    rename_column :participants, :badge_id, :badgelet_id
    add_index :badgelets, :creator_id, name: "index_badgelets_on_creator_id"
    add_index :badgelets, :owner_id, name: "index_badgelets_on_owner_id"
    add_foreign_key "group_invites", "badgelets"
    add_foreign_key "map_checkins", "badgelets"
    add_foreign_key "participants", "badgelets"
  end
end
