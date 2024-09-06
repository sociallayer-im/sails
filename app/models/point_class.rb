class PointClass < ApplicationRecord
  belongs_to :creator, class_name: "Profile", foreign_key: "creator_id"
  belongs_to :group, optional: true
end
