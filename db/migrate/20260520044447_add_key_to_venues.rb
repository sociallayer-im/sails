class AddKeyToVenues < ActiveRecord::Migration[7.2]
  def up
    add_column :venues, :key, :string
    add_index :venues, :key, unique: true

    # Backfill existing records using created_at timestamp
    generator = Tsid::Generator.new
    Venue.order(:created_at, :id).each do |venue|
      venue.update_column(:key, generator.generate(venue.created_at))
    end

    change_column_null :venues, :key, false
  end

  def down
    remove_column :venues, :key
  end
end
