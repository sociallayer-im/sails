class AddActivityField < ActiveRecord::Migration[7.1]
  def change
    add_column :activities, :receiver_id, :integer
    add_column :activities, :receiver_type, :string, default: "id"
    add_column :activities, :receiver_address, :string
    add_column :activities, :has_read, :boolean, default: false

    add_column :signin_activities, :remote_ip, :string
    add_column :signin_activities, :locale, :string
    add_column :signin_activities, :lang, :string
  end
end
