class CreatePointBalances < ActiveRecord::Migration[7.2]
  def change
    create_table :point_balances do |t|
      t.integer "point_class_id"
      t.integer "creator_id"
      t.integer "owner_id"
      t.integer "value", default: 0
      t.timestamps
    end
  end
end
