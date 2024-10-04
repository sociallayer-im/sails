class CreatePoints < ActiveRecord::Migration[7.1]
  def change
    create_table :points do |t|
      t.integer "point_class_id"
      t.integer "creator_id"
      t.integer "owner_id"
      t.integer "value", default: 0
      t.datetime "created_at", null: false
    end
  end
end
