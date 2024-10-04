class AddGroupVenueInfo < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :group_space_logo_url, :string
    add_column :groups, :event_site_tags, :string, array: true
    add_column :groups, :event_requirement_tags, :string, array: true
    add_column :event_sites, :require_approval, :boolean, default: false
    add_column :event_sites, :tags, :string, array: true
    add_column :events, :schedule_details, :jsonb
    add_column :events, :requirement_tags, :string, array: true
  end
end
