class AddEventSiteInfo < ActiveRecord::Migration[7.1]
  def change
    add_column :event_sites, :link, :string
    add_column :event_sites, :capacity, :integer
    add_column :event_sites, :overrides, :jsonb
  end
end
