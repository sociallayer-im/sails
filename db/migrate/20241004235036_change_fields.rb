class ChangeFields < ActiveRecord::Migration[7.1]
  def change
    add_column :badge_classes, :status, :string, default: "active"
    add_column :profiles, :social_links, :jsonb, default: {}
    add_column :profiles, :handle, :string
    add_column :groups, :handle, :string
    add_column :comments, :status, :string, default: "active"
    rename_column :coupons, :expiry_time, :expires_at
    add_column :vouchers, :data, :jsonb, comment: "start_time, end_time, value, transferable, revocable"
    add_column :comments, :comment_type, :string
    rename_column :event_roles, :profile_id, :item_id
    add_column :event_roles, :item_type, :string
    add_column :badge_classes, :can_send_badge, :string, default: "owner"
    add_column :events, :extras, :jsonb, default: {}
    rename_column :comments, :sender_id, :profile_id
    rename_column :comments, :topic_title, :title
    rename_column :comments, :topic_item_type, :item_type
    rename_column :comments, :topic_item_id, :item_id
    add_column :comments, :icon_url, :string
    add_column :comments, :edit_parent_id, :integer
    add_column :comments, :badge_id, :integer
    add_column :comments, :updated_at, :datetime
  end
end
