class CreateCustomForms < ActiveRecord::Migration[7.2]
  def change
    create_table :custom_forms do |t|
      t.string :title
      t.string :description
      t.string :status
      t.string :item_type
      t.integer :item_id
      t.integer :group_id
      t.timestamps
    end
  end
end
