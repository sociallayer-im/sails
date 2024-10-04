class AddEventSiteRemoved < ActiveRecord::Migration[7.1]
  def change
    add_column :event_sites, :removed, :boolean
    remove_column :memberships, :data
    add_column :memberships, :data, :jsonb
  end
end
