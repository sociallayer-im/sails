class AddTicketLinkToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :ticket_link, :string
  end
end
