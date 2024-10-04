class AddTicketPaymentTokenPrice < ActiveRecord::Migration[7.1]
  def change
    add_column :tickets, :payment_token_price, :integer
  end
end
