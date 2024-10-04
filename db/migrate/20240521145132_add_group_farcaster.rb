class AddGroupFarcaster < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :farcaster, :string
  end
end
