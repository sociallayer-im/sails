class AddAdminNotificationToMemberships < ActiveRecord::Migration[7.2]
  def change
    add_column :memberships, :admin_notification, :boolean, default: false, null: false
  end
end
