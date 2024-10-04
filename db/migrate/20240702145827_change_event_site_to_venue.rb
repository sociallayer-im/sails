class ChangeEventSiteToVenue < ActiveRecord::Migration[7.1]
  def up
    remove_foreign_key "event_sites", "groups"
    remove_foreign_key "event_sites", "profiles", column: "owner_id"
    rename_column :events, :event_site_id, :venue_id
    rename_table :event_sites, :venues
  end

  def down
    add_foreign_key "event_sites", "groups"
    add_foreign_key "event_sites", "profiles", column: "owner_id"
    rename_column :events, :venue_id, :event_site_id
    rename_table :venues, :event_sites
  end
end
