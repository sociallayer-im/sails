class AddEventNotes < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :notes, :text
  end
end
