class AddTelegramData < ActiveRecord::Migration[7.2]
  def change
    add_column :profiles, :telegram_data, :jsonb
    add_column :profiles, :telegram_id, :string
  end
end
