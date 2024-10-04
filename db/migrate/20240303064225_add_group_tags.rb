class AddGroupTags < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :memberships_count, :integer, null: false, default: 0
    add_column :groups, :events_count, :integer, null: false, default: 0
    add_column :groups, :group_tags, :string, array: true
    add_column :popup_cities, :group_tags, :string, array: true
  end
end
