class Availability < ApplicationRecord
  belongs_to :item, polymorphic: true

  validates :day_of_week, inclusion: { in: %w(monday tuesday wednesday thursday friday saturday sunday) }, allow_nil: true
end
