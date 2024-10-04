class AddProfileEdgeCityData < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :zupass_edge_event_id, :string
    add_column :profiles, :zupass_edge_product_id, :string
    add_column :profiles, :zupass_edge_product_name, :string
    add_column :profiles, :zupass_edge_start_date, :date
    add_column :profiles, :zupass_edge_end_date, :date
    add_column :profiles, :zupass_edge_weekend, :boolean, default: false
  end
end
