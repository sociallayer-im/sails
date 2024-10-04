class AddGroupTimezone < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :timezone, :string
    add_column :groups, :map_preview_url, :string
    add_column :events, :padge_link, :string
  end
end
