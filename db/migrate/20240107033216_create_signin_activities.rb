class CreateSigninActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :signin_activities do |t|
      t.string   "app"
      t.string   "address"
      t.string   "address_type"
      t.string   "address_source"
      t.integer  "profile_id"
      t.text     "data"
      t.datetime "created_at", null: false
    end
  end
end
