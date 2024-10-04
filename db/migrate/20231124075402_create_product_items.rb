class CreateProductItems < ActiveRecord::Migration[7.1]
  def change
    create_table :product_items do |t|
      t.integer "product_id"
      t.string "label"
      t.string "image_url"
      t.integer "inventory" # todo : change name
      t.integer "price"
      t.integer "payment_point_class_id"
      t.integer "payment_badge_id" # todo : change name
      t.integer "index", null: false, default: 0
      t.string "status", null: false, default: "normal", comment: "draft | normal | closed"
      t.datetime "created_at", null: false
    end
  end
end
