class AddVenueAmenities < ActiveRecord::Migration[7.2]
  def change
    add_column :venues, :amenities, :string, array: true, default: []
    add_column :venues, :image_urls, :string, array: true, default: []
    add_column :venues, :featured_image_url, :string
  end
end
