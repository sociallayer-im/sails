class CreateTicketItems < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_items do |t|
      t.string :status
      t.integer :profile_id
      t.integer :ticket_id
      t.integer :event_id
      t.string :chain
      t.string :txhash
      t.integer :amount
      t.string :ticket_price
      t.string :discount_value
      t.string :discount_data
      t.string :order_number
      t.timestamps
    end
  end
end
