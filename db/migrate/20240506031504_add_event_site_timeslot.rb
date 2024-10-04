class AddEventSiteTimeslot < ActiveRecord::Migration[7.1]
  def change
    add_column :event_sites, :start_date, :date
    add_column :event_sites, :end_date, :date
    add_column :event_sites, :timeslots, :jsonb
  end
end
