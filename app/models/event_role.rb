class EventRole < ApplicationRecord
  belongs_to :event
  belongs_to :profile, optional: true
end
