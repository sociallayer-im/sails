class ChangeEventRole < ActiveRecord::Migration[7.1]
  def change
    add_column    :event_roles, :role, :string
    change_column :event_roles, :email, :string
    change_column :event_roles, :nickname, :string
    change_column :event_roles, :image_url, :string
    remove_column :event_roles, :group_id, :string
    remove_column :venue_timeslots, :group_id, :string
    remove_column :venue_overrides, :group_id, :string
  end
end
