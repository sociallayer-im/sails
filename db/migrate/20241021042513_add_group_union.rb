class AddGroupUnion < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :group_union, :integer, array: true
    add_column :events, :location_data, :string
    add_column :venues, :location_data, :string
    add_column :markers, :location_data, :string
  end
end
