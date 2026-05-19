class AddFeaturedImageUrlToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :featured_image_url, :string
  end
end
