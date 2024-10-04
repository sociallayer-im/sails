class CreateGroupPasses < ActiveRecord::Migration[7.1]
  def change
    create_table :group_passes do |t|
      t.integer "group_id"
      t.integer "profile_id"
      t.string  "pass_type"
      t.string  "zupass_event_id"
      t.string  "zupass_product_id"
      t.string  "zupass_product_name"
      t.date    "start_date"
      t.date    "end_date"
      t.date    "days_allowed", array: true
      t.date    "days_disallowed", array: true
      t.boolean "weekend", default: false
      t.timestamps
    end
  end
end
