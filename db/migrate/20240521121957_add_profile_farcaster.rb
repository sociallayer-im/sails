class AddProfileFarcaster < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :farcaster, :string
    add_column :events, :extra, :string, array: true
  end
end
