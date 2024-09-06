class Marker < ApplicationRecord
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id"
  belongs_to :group, optional: true
  belongs_to :event, optional: true
  has_many :comments, as: :item, dependent: :delete_all

  validates :marker_type, inclusion: { in: %w(site event share) }
  validates :status, inclusion: { in: %w(active removed) }
end
