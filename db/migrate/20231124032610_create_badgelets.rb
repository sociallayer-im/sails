class CreateBadgelets < ActiveRecord::Migration[7.1]
  def change
    create_table :badgelets do |t|
      t.integer  "index"
      t.integer  "badge_id"
      t.integer  "creator_id"
      t.integer  "owner_id"
      t.string   "image_url"
      t.string   "title"
      t.text     "metadata"
      t.text     "content"
      t.string   "status", default: "new", null: false, comment: "new | burnt"
      t.string   "display", default: "normal", null: false, comment: "normal | hide | top"
      t.string   "hashtags", array: true
      t.integer  "value", default: 0
      t.datetime "last_value_used_at"
      t.datetime "start_time"
      t.datetime "end_time"
      t.string   "chain_index"
      t.string   "chain_space"
      t.string   "chain_txhash"
      t.integer  "voucher_id"
      t.datetime "created_at"
      t.index ["badge_id"], name: "index_badgelets_on_badge_id"
      t.index ["owner_id"], name: "index_badgelets_on_owner_id"
      t.index ["creator_id"], name: "index_badgelets_on_creator_id"
    end
  end
end
