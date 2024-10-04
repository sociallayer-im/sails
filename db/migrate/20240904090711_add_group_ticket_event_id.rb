class AddGroupTicketEventId < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :group_ticket_event_id, :integer
  end
end
