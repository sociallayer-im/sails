class AddGroupInviteReceiverType < ActiveRecord::Migration[7.1]
  def change
    add_column :group_invites, :receiver_address_type, :string, default: "id"
    add_column :group_invites, :receiver_address, :string
  end
end
