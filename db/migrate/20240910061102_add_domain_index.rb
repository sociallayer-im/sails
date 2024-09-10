class AddDomainIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :domains, :handle, unique: true
    add_index :memberships, [:profile_id, :group_id], unique: true
    add_index :participants, [:profile_id, :event_id], unique: true
  end
end
