class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.string :title
      t.string :content
      t.integer :event_id
      t.integer :check_badge_id
      t.integer :quantity
      t.datetime :end_time
      t.boolean :need_approval
      t.string :status, default: "normal"
      t.string :payment_chain
      t.string :payment_token_name
      t.string :payment_token_address
      t.string :payment_target_address
      t.datetime :created_at, null: false
    end

    add_column :participants, :ticket_id, :integer
  end
end
