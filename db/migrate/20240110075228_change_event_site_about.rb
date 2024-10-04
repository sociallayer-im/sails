class ChangeEventSiteAbout < ActiveRecord::Migration[7.1]
  def change
    change_column :event_sites, :about, :text
  end
end
