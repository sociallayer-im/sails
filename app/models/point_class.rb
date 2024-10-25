class PointClass < ApplicationRecord
  belongs_to :creator, class_name: "Profile", foreign_key: "creator_id"
  belongs_to :group, optional: true

  validates :name, length: { minimum: 2 }
  validates :name, format: { with: /\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\z/,
    message: "only allows alphanumeric characters and hyphens" }
end
