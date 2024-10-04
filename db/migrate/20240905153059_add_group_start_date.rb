class AddGroupStartDate < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :start_date, :date
    add_column :groups, :end_date, :date
  end
end
