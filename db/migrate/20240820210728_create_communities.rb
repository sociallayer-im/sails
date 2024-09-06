class CreateCommunities < ActiveRecord::Migration[7.2]
  def change
    create_table :communities do |t|
      t.string "title"
      t.string "image_url"
      t.string "location"
      t.string "website"
      t.integer "group_id"
      t.date "start_date"
      t.date "end_date"
      t.string "kind", comment: "popup_city | community"
      t.string "group_tags", array: true
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
