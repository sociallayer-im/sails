class AddEventOperator < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :operators, :integer, array: true
    add_column :groups, :can_publish_event_with_approval, :string, default: "none", comment: "member | everyone | none"
  end
end
