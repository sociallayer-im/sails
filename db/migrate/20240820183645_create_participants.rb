class CreateParticipants < ActiveRecord::Migration[7.2]
  def change
    create_table :participants do |t|
      t.integer "event_id"
      t.integer "profile_id"
      t.text "message"
      t.string "status", default: "attending", null: false, comment: "attending | pending | disapproved | checked | cancel"
      t.datetime "register_time"
      t.datetime "check_time"
      t.string "payment_status"
      t.jsonb "payment_data"
      t.timestamps
    end
  end
end
