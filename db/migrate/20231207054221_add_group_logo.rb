class AddGroupLogo < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :logo_url, :string
  end
end
