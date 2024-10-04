class AddEventSiteVisibility < ActiveRecord::Migration[7.1]
  def change
    add_column :event_sites, :visibility, :string, comment: "all | manager | none"
  end
end
