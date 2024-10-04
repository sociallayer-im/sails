class CreateVenueOverrides < ActiveRecord::Migration[7.1]
  def change
    create_table :venue_overrides do |t|
      t.integer :group_id
      t.integer :venue_id
      t.date    :day
      t.boolean :disabled
      t.string  :start_at
      t.string  :end_at
      t.timestamps
    end
  end
end
