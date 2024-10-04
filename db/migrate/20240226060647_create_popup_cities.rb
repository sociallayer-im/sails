class CreatePopupCities < ActiveRecord::Migration[7.1]
  def change
    create_table :popup_cities do |t|
      t.string :title
      t.string :image_url
      t.string :location
      t.string :website
      t.integer :group_id
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
  end
end
