class CreateVoteProposals < ActiveRecord::Migration[7.2]
  def change
    create_table :vote_proposals do |t|
      t.string "title"
      t.text "content"
      t.integer "group_id"
      t.integer "creator_id"
      t.string "eligibility", default: "has_group_membership", null: false, comment: "has_group_membership | everyone | is_verified | is_verified_in_group | has_badge | badge_count | max_badge_weight | total_badge_weight | points_count | above_points_threshold"
      t.integer "eligibile_group_id"
      t.integer "eligibile_badge_class_id"
      t.integer "eligibile_point_id"
      t.string "verification"
      t.string "status", default: "published", null: false, comment: "draft | published | closed | cancelled"
      t.boolean "show_voters"
      t.boolean "can_update_vote"
      t.integer "voter_count", default: 0
      t.integer "weight_count", default: 0
      t.integer "max_choice", default: 1
      t.datetime "start_time"
      t.datetime "end_time"
      t.datetime "created_at", null: false
    end
  end
end
