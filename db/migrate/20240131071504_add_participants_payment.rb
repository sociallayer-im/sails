class AddParticipantsPayment < ActiveRecord::Migration[7.1]
  def change
    add_column :participants, :payment_status, :string
    add_column :participants, :payment_data, :string
    add_column :events, :external_url, :string
  end
end
