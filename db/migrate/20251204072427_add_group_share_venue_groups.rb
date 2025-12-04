class AddGroupShareVenueGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :venue_union, :integer, array: true
  end
end
