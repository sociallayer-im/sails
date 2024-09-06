class CreateBadgeClasses < ActiveRecord::Migration[7.2]
  def change
    create_table :badge_classes do |t|
      t.string "domain"
      t.string "name"
      t.string "title"
      t.jsonb "metadata"
      t.text "content"
      t.string "image_url"
      t.integer "creator_id"
      t.integer "group_id"
      t.integer "counter", default: 1
      t.string "tags", array: true
      t.boolean "transferable", default: false, null: false
      t.boolean "revocable", default: false, null: false
      t.boolean "weighted", default: false, null: false
      t.boolean "encrypted", default: false, null: false
      t.string "permissions", default: [], array: true
      t.string "chain_index"
      t.string "chain_space"
      t.string "chain_txhash"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "status", default: "active"
      t.string "display", default: "normal"
      t.index ["creator_id"], name: "index_badge_classes_on_creator_id"
    end
  end
end
