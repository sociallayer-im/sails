class AddBadgeClassStatus < ActiveRecord::Migration[7.1]
  def change
    add_column :badge_classes, :status, :string, default: "active"
    add_column :profiles, :handle, :string
    add_column :groups, :handle, :string
  end
end
