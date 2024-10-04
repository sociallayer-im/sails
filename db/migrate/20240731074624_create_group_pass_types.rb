class CreateGroupPassTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :group_pass_types do |t|
      t.string :title
      t.integer :group_id
      t.string :zupass_event_id
      t.string :zupass_product_id
      t.string :zupass_product_name
      t.date :start_date
      t.date :end_date
      t.date :days_allowed, array: true
      t.string :tracks_allowed, array: true
      t.string :image_url
      t.timestamps
    end
  end
end
