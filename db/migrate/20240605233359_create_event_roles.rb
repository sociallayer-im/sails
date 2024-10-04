class CreateEventRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :event_roles do |t|
      t.integer :group_id
      t.integer :event_id
      t.integer :profile_id
      t.integer :email
      t.integer :nickname
      t.integer :image_url
      t.timestamps
    end
  end
end
