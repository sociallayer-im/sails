class RenameCoupon < ActiveRecord::Migration[7.1]
  def change
    rename_table :promo_codes, :coupons
    rename_column :ticket_items, :promo_code_id, :coupon_id

    rename_table :chat_messages, :comments

    rename_table :point_items, :point_transfers
    rename_column :point_transfers, :owner_id, :receiver_id

    rename_table  :points, :point_balances
  end
end
