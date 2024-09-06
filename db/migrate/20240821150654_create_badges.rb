class CreateBadges < ActiveRecord::Migration[7.2]
  def change
    create_table :badges do |t|
      t.string "domain"
      t.integer "index"
      t.integer "badge_class_id"
      t.integer "creator_id"
      t.integer "owner_id"
      t.string "image_url"
      t.string "title"
      t.jsonb "metadata"
      t.text "content"
      t.string "status", default: "minted", null: false, comment: "minted | burned"
      t.string "display", default: "normal"
      t.string "tags", array: true
      t.integer "value", default: 0
      t.datetime "start_time"
      t.datetime "end_time"
      t.string "chain_index"
      t.string "chain_space"
      t.string "chain_txhash"
      t.integer "voucher_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
