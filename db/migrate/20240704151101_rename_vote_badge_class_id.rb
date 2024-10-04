class RenameVoteBadgeClassId < ActiveRecord::Migration[7.1]
  def up
    remove_foreign_key "vote_proposals", "badge_classes", column: "eligibile_badge_id"
    rename_column :vote_proposals, :eligibile_badge_id, :eligibile_badge_class_id
    rename_column :tickets, :check_badge_id, :check_badge_class_id
  end

  def down
    rename_column :tickets, :check_badge_class_id, :check_badge_id
    rename_column :vote_proposals, :eligibile_badge_class_id, :eligibile_badge_id
    add_foreign_key "vote_proposals", "badge_classes", column: "eligibile_badge_id"
  end
end
