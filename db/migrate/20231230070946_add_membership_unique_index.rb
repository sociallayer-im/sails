class AddMembershipUniqueIndex < ActiveRecord::Migration[7.1]
  def change
    add_index :memberships, [:profile_id, :target_id], unique: true
  end
end
