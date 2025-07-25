class AddEventOperatorInfo < ActiveRecord::Migration[7.2]
  def change
    add_column :events, :op_status, :string
    add_column :events, :op_priority, :string
    add_column :events, :op_labels, :string, array: true, default: []
    add_column :events, :assigned_operators, :integer, array: true, default: []

    add_column :groups, :op_label_list, :string, array: true, default: []
  end
end
