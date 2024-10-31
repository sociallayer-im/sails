class AddEventGroupIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :participants, :profile_id
    add_index :participants, :event_id
    add_index :events, :group_id
  end
end
