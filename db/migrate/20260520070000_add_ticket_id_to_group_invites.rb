class AddTicketIdToGroupInvites < ActiveRecord::Migration[7.2]
  def change
    add_column :group_invites, :ticket_id, :integer unless column_exists?(:group_invites, :ticket_id)
  end
end
