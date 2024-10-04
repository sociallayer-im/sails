class CreateConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :configs do |t|
      t.integer :group_id
      t.integer :item_id
      t.string :item_type
      t.string :name
      t.string :value
      t.jsonb :data
      t.timestamps
    end
  end
end
