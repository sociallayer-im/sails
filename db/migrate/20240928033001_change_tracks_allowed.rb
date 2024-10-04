class ChangeTracksAllowed < ActiveRecord::Migration[7.1]
  def change
    remove_column :tickets, :tracks_allowed, :string, array: true
    add_column :tickets, :tracks_allowed, :integer, array: true, default: []
  end
end
