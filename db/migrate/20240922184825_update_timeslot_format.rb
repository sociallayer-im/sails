class UpdateTimeslotFormat < ActiveRecord::Migration[7.2]
  def change
    add_column :venue_timeslots, :data, :jsonb
    add_column :venue_overrides, :data, :jsonb
  end
end
