class AddTicketItemReceiverAddress < ActiveRecord::Migration[7.1]
  def change
    add_column :ticket_items, :selector_type, :string
    add_column :ticket_items, :selector_address, :string
    add_column :ticket_items, :original_price, :decimal, precision: 40
    remove_column :tracks, :original_price, :decimal, precision: 40
  end
end
