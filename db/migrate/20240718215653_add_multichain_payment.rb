class AddMultichainPayment < ActiveRecord::Migration[7.1]
  def change
    add_column :tickets, :payment_metadata, :jsonb
    add_column :participants, :payment_chain, :string
    add_column :group_passes, :allow_tags, :string, array: true
  end
end
