class Marker < ApplicationRecord
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id"
  belongs_to :group, optional: true
  belongs_to :event, optional: true
  belongs_to :badge_class, optional: true
  belongs_to :place, optional: true
  has_many :comments, as: :item, dependent: :delete_all

  # Location fields were extracted to the `places` table; expose them as
  # read-only delegates so existing call sites keep working.
  def location          = place&.name
  def formatted_address = place&.address
  def geo_lat           = place&.geo_lat
  def geo_lng           = place&.geo_lng
  def location_viewport = place&.location_viewport

  validates :marker_type, inclusion: { in: %w(site event share) }
  validates :status, inclusion: { in: %w(active removed) }
end
