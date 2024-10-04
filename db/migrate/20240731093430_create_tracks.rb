class CreateTracks < ActiveRecord::Migration[7.1]
  def change
    create_table :tracks do |t|
      t.string :tag
      t.string :title
      t.string :kind, comment: "public | private"
      t.string :icon_url
      t.string :about
      t.integer :group_id
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
  end
end
