class CreateBadges < ActiveRecord::Migration[7.1]
  def change
    create_table :badges do |t|
      t.string   "name"
      t.string   "title"
      t.text     "metadata"
      t.text     "content"
      t.string   "image_url"
      t.integer  "creator_id"
      t.integer  "group_id"
      t.integer  "counter", default: 1
      t.string   "hashtags", array: true
      t.boolean  "transferable", default: false, null: false
      t.boolean  "revocable", default: false, null: false
      t.boolean  "weighted", default: false, null: false
      t.boolean  "encrypted", default: false, null: false
      t.string   "badge_type", default: "badge", null: false, comment: "badge | nft | nftpass | private"
      t.string   "permissions", default: [], array: true
      t.string   "chain_index"
      t.string   "chain_space"
      t.string   "chain_txhash"
      t.datetime "created_at", null: false
      t.index ["creator_id"], name: "index_badges_on_creator_id"
    end
  end
end
