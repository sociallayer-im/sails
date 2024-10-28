class ChangeActivityItemType < ActiveRecord::Migration[7.2]
  def change
    remove_column :activities, :item_type, :integer
    add_column :activities, :item_type, :string

    remove_column :activities, :target_type, :integer
    add_column :activities, :target_type, :string
  end
end
