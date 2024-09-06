class CreateVoteOptions < ActiveRecord::Migration[7.2]
  def change
    create_table :vote_options do |t|
      t.integer "group_id"
      t.integer "vote_proposal_id"
      t.string "title"
      t.string "link"
      t.string "content"
      t.string "image_url"
      t.integer "voted_weight", default: 0
      t.datetime "created_at", null: false
    end
  end
end
