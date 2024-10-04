class ChangePromoCode < ActiveRecord::Migration[7.1]
  def change
    change_column :promo_codes, :discount_type, :string
    add_column :ticket_items, :payment_method_id, :integer
    add_column :ticket_items, :token_address, :integer
    add_column :ticket_items, :receiver_address, :integer
  end
end
