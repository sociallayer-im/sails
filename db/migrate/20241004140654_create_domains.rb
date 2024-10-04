class CreateDomains < ActiveRecord::Migration[7.1]
  def change
    create_table :domains do |t|
      t.string "handle"
      t.string "fullname"
      t.string "item_type"
      t.integer "item_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["handle"], name: "index_domains_on_handle", unique: true
    end
  end
end
