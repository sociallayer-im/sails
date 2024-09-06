class CreateVoteRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :vote_records do |t|
      t.integer "group_id"
      t.integer "voter_id"
      t.integer "vote_proposal_id"
      t.integer "vote_options", array: true
      t.boolean "replaced", default: false
      t.datetime "created_at", null: false
    end
  end
end
