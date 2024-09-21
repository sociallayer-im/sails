class AdaptTable < ActiveRecord::Migration[7.2]
  def change
    remove_column :activities, :context
    change_column :badge_classes, :updated_at, :datetime, null: true
    add_column :badge_classes, :extras, :jsonb, default: {}
    add_column :badges, :extras, :jsonb, default: {}
    change_column :comments, :updated_at, :datetime, null: true
    change_column :comments, :created_at, :datetime, null: true
    change_column :contacts, :updated_at, :datetime, null: true
    rename_column :event_roles, :profile_id, :item_id
    add_column :event_roles, :item_type, :string, default: "Profile"
    rename_column :events, :extra, :extras
    change_column :events, :extras, :jsonb, default: {}
    change_column :events, :updated_at, :datetime, null: true
    change_column :group_invites, :data, :jsonb, default: {}
    change_column :group_invites, :updated_at, :datetime, null: true
    change_column :group_invites, :created_at, :datetime, null: true
    remove_column :groups, :chain, :string
    remove_column :groups, :can_publish_event
    remove_column :groups, :can_join_event
    remove_column :groups, :can_view_event
    rename_column :groups, :extra, :extras
    change_column :groups, :extras, :jsonb, default: {}
    change_column :groups, :updated_at, :datetime, null: true
    change_column :markers, :updated_at, :datetime, null: true
    change_column :markers, :data, :jsonb, default: {}
    remove_column :participants, :payment_data, :jsonb
    add_column :participants, :extras, :jsonb, default: {}
    change_column :participants, :updated_at, :datetime, null: true
    change_column :payment_methods, :updated_at, :datetime, null: true
    change_column :payment_methods, :price, :integer
    change_column :point_classes, :updated_at, :datetime, null: true
    remove_column :profiles, :chain, :string
    change_column :profiles, :updated_at, :datetime, null: true
    change_column :recurrings, :created_at, :datetime, null: true
    change_column :recurrings, :updated_at, :datetime, null: true
    remove_column :ticket_items, :ticket_order_id, :integer
    change_column :tickets, :updated_at, :datetime, null: true
    add_column :venues, :timeslots, :jsonb, default: {}
    add_column :venues, :overrides, :jsonb, default: {}
    change_column :venues, :updated_at, :datetime, null: true
    change_column :vouchers, :updated_at, :datetime, null: true
    rename_column :vouchers, :badge_data, :data
  end
end
