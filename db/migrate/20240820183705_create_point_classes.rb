class CreatePointClasses < ActiveRecord::Migration[7.2]
  def change
    create_table :point_classes do |t|
      t.string "name"
      t.string "title"
      t.string "sym", default: "pt", null: false
      t.jsonb "metadata"
      t.text "content"
      t.string "image_url"
      t.integer "creator_id"
      t.integer "group_id"
      t.boolean "transferable", default: false, null: false
      t.boolean "revocable", default: false, null: false
      t.string "point_type", default: "point", null: false, comment: "point | credit"
      t.integer "total_supply", default: 0
      t.integer "max_supply"
      t.index ["creator_id"], name: "index_point_classes_on_creator_id"
      t.timestamps
    end
  end
end
