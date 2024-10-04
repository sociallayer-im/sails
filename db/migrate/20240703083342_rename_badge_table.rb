class RenameBadgeTable < ActiveRecord::Migration[7.1]
  def up
    remove_foreign_key "badgelets", "badges"
    remove_foreign_key "badgelets", "profiles", column: "creator_id"
    remove_foreign_key "badgelets", "profiles", column: "owner_id"
    remove_foreign_key "badgelets", "vouchers"
    remove_foreign_key "badges", "groups"
    remove_foreign_key "badges", "profiles", column: "creator_id"
    remove_index :badgelets, :badge_id, name: "index_badgelets_on_badge_id"
    remove_index :vouchers, :badge_id, name: "index_vouchers_on_badge_id"
    rename_column :badgelets, :badge_id, :badge_class_id
    rename_column :markers, :badge_id, :badge_class_id
    rename_column :vouchers, :badge_id, :badge_class_id
    rename_column :events, :badge_id, :badge_class_id
    rename_column :group_invites, :badge_id, :badge_class_id
    rename_table :badges, :badge_classes
  end

  def down
    rename_column :badgelets, :badge_class_id, :badge_id
    rename_column :markers, :badge_class_id, :badge_id
    rename_column :vouchers, :badge_class_id, :badge_id
    rename_column :events, :badge_class_id, :badge_id
    rename_column :group_invites, :badge_class_id, :badge_id
    add_index :badgelets, :badge_id, name: "index_badgelets_on_badge_id"
    add_index :vouchers, :badge_id, name: "index_vouchers_on_badge_id"
    add_foreign_key "badgelets", "badges"
    add_foreign_key "badgelets", "profiles", column: "creator_id"
    add_foreign_key "badgelets", "profiles", column: "owner_id"
    add_foreign_key "badgelets", "vouchers"
    add_foreign_key "badges", "groups"
    add_foreign_key "badges", "profiles", column: "creator_id"
    rename_table :badges_classes, :badge
  end
end
