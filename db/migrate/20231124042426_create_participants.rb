class CreateParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :participants do |t|
      t.integer "event_id"
      t.integer "profile_id"
      t.text    "message"
      t.string  "role", comment: "attendee | speaker | organizer"
      t.integer "voucher_id"
      t.integer "badgelet_id"
      t.string  "status", default: "applied", null: false, comment: "applied | pending | disapproved | checked | cancel"
      t.datetime "check_time"
      t.datetime "created_at", null: false
    end
  end
end
