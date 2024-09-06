class Activity < ApplicationRecord
  belongs_to :item, polymorphic: true, optional: true
  belongs_to :initiator, class_name: "Profile", foreign_key: "initiator_id"
end
