class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.integer "estore_id"
      t.string "title"
      t.string "image_urls", array: true
      t.string "memo"
      t.string "start_time"
      t.string "end_time"
      t.string "product_type"
      t.string "status", default: "normal", null: false, comment: "draft | normal | closed"
      t.text "content"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
