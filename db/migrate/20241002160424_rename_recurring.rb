class RenameRecurring < ActiveRecord::Migration[7.1]
  def change
    rename_table :recurring_events, :recurrings
    rename_column :events, :recurring_event_id, :recurring_id
  end
end
