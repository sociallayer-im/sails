class AddEventTrackId < ActiveRecord::Migration[7.1]
  def change
    add_column    :groups, :social_links, :jsonb, default: {}
    add_column    :groups, :updated_at, :datetime

    add_column    :events, :track_id, :integer
    add_column    :events, :updated_at, :datetime

    add_column :tracks, :manager_ids, :integer, array: true

    add_column :tracks, :original_price, :decimal, precision: 40

    add_column    :badge_classes, :updated_at, :datetime
    add_column    :badges, :updated_at, :datetime
    add_column    :profiles, :updated_at, :datetime
    add_column    :tickets, :updated_at, :datetime
    add_column    :venues, :updated_at, :datetime
    add_column    :markers, :updated_at, :datetime
    add_column    :memberships, :updated_at, :datetime
  end
end
