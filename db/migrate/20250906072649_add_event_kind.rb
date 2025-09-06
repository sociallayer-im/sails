class AddEventKind < ActiveRecord::Migration[7.2]
  def change
    add_column :events, :kind, :string
  end
end
