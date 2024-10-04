class AddBadgeFields < ActiveRecord::Migration[7.1]
  def change
    add_column :badges, :display, :string, default: "normal", comment: "normal | hide | top"
    add_column :badges, :domain, :string
    add_column :badgelets, :domain, :string
    add_column :memberships, :cap, :string
    add_column :memberships, :data, :string, array: true
  end
end
