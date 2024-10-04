class ChangeGroupPass < ActiveRecord::Migration[7.1]
  def change
    add_column :group_passes, :title, :string
    add_column :group_passes, :pass_type_id, :integer
    add_column :group_passes, :ticket_id, :integer
    add_column :group_passes, :tracks_allowed, :string, array: true
    add_column :groups, :main_event_id, :integer
    add_column :groups, :stripe_app_key, :string
    add_column :groups, :stripe_app_secret, :string
    add_column :groups, :stripe_callback, :string
    add_column :groups, :stripe_data, :string
    rename_column :group_passes, :days_disallowed, :days_blocked
    rename_column :group_passes, :pass_type, :auth_type
  end
end
