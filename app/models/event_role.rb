class EventRole < ApplicationRecord
  belongs_to :event
  belongs_to :profile, optional: true
  belongs_to :item, polymorphic: true, optional: true
end
