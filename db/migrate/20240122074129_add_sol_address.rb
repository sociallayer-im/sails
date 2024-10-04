class AddSolAddress < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :sol_address, :string
  end
end
