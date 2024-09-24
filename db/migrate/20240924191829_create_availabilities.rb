class CreateAvailabilities < ActiveRecord::Migration[7.2]
  def change
    create_table :availabilities do |t|
      t.integer "item_id"
      t.string "item_type"
      t.string "day_of_week"
      t.date "day"
      t.jsonb "intervals"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
