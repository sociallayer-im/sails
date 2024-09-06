class CreateSigninActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :signin_activities do |t|
      t.string "app"
      t.string "address"
      t.string "address_type"
      t.string "address_source"
      t.integer "profile_id"
      t.text "data"
      t.datetime "created_at", null: false
      t.string "remote_ip"
      t.string "locale"
      t.string "lang"
    end
  end
end
