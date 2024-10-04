class CreateVenueTimeslots < ActiveRecord::Migration[7.1]
  def change
    create_table :venue_timeslots do |t|
      t.integer :group_id
      t.integer :venue_id
      t.string  :day_of_week
      t.boolean :disabled
      t.string  :start_at
      t.string  :end_at
      t.timestamps
    end
  end
end
