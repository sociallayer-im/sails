class AddDataToPlaces < ActiveRecord::Migration[7.2]
  def change
    add_column :places, :data, :string, comment: "Google Maps place_id"
  end
end
