class ChangePriceToInt8InPaymentMethods < ActiveRecord::Migration[7.2]
  def change
    change_column :payment_methods, :price, :bigint
  end
end
