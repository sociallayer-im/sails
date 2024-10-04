class AddRegisterTime < ActiveRecord::Migration[7.1]
  def change
    add_column :participants, :register_time, :datetime
  end
end
