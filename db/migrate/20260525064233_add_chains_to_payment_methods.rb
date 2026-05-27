class AddChainsToPaymentMethods < ActiveRecord::Migration[7.2]
  def change
    add_column :payment_methods, :chains, :string, array: true, default: []
    add_column :payment_methods, :chain_token_addresses, :jsonb, default: {}
  end
end
