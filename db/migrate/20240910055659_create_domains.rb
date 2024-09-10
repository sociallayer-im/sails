class CreateDomains < ActiveRecord::Migration[7.2]
  def change
    create_table :domains do |t|
      t.string :handle
      t.string :fullname
      t.string :item_type
      t.integer :item_id
      t.timestamps
    end
  end
end
