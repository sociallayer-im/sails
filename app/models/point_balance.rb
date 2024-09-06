class PointBalance < ApplicationRecord
  belongs_to :point_class
  belongs_to :creator, class_name: "Profile", foreign_key: "creator_id"
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id"
  has_many :point_transfers, dependent: :delete_all
  has_many :activities, as: :item, dependent: :delete_all
end
