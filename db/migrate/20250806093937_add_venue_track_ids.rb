class AddVenueTrackIds < ActiveRecord::Migration[7.2]
  def change
    add_column :venues, :track_ids, :integer, array: true, default: []
  end
end
