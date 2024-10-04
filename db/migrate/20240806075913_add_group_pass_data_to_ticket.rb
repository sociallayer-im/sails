class AddGroupPassDataToTicket < ActiveRecord::Migration[7.1]
  def change
    add_column :tickets, :ticket_type, :string, default: "event", comment: "event | group"
    add_column :tickets, :group_id, :integer
    add_column :tickets, :zupass_event_id, :string
    add_column :tickets, :zupass_product_id, :string
    add_column :tickets, :zupass_product_name, :string
    add_column :tickets, :start_date, :date
    add_column :tickets, :end_date, :date
    add_column :tickets, :days_allowed, :date, array: true
    add_column :tickets, :tracks_allowed, :string, array: true

    add_column :ticket_items, :ticket_type, :string, default: "event", comment: "event | group"
    add_column :ticket_items, :group_id, :integer
    add_column :ticket_items, :auth_type, :string, comment: "free | payment | zupass | badge | invite"
    add_column :ticket_items, :tracks_allowed, :string, array: true

    add_column :groups, :customizer, :string
    add_column :groups, :group_ticket_enabled, :boolean, default: false

  end
end
