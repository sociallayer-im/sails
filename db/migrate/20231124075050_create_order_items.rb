class CreateOrderItems < ActiveRecord::Migration[7.1]
  def change
    create_table :order_items do |t|
      t.integer "order_id"
      t.integer "product_id"
      t.integer "product_item_id"
      t.integer "quantity"
      t.datetime "created_at", null: false
    end
  end
end
