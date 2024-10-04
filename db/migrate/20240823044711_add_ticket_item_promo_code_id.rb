class AddTicketItemPromoCodeId < ActiveRecord::Migration[7.1]
  def change
    add_column :ticket_items, :promo_code_id, :integer
    add_column :ticket_items, :sender_address, :string
  end
end
