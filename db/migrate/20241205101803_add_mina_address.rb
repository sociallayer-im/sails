class AddMinaAddress < ActiveRecord::Migration[7.2]
  def change
    add_column :profiles, :mina_address, :string
    add_column :profiles, :fuel_address, :string
    add_column :availabilities, :role, :string
    add_column :venue_timeslots, :role, :string
    add_column :venue_overrides, :role, :string
  end
end
