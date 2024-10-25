class AddEventPinned < ActiveRecord::Migration[7.2]
  def change
    add_column :events, :pinned, :boolean, default: false
    add_column :events, :theme, :string
  end
end
