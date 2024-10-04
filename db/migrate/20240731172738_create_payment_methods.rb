class CreatePaymentMethods < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_methods do |t|
      t.string :item_type
      t.integer :item_id
      t.string :chain
      t.string :kind
      t.string :token_name
      t.string :token_address
      t.string :receiver_address
      t.integer :price
      t.timestamps
    end

    add_column :ticket_items, :participant_id, :integer
  end
end
