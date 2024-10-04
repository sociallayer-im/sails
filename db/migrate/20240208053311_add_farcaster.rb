class AddFarcaster < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :far_fid, :string
    add_column :profiles, :far_address, :string
  end
end
