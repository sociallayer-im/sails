class AddPaymentProtocol < ActiveRecord::Migration[7.2]
  def change
    add_column :payment_methods, :protocol, :string
    add_column :ticket_items, :protocol, :string
  end
end
