class VenueTimeslot < ApplicationRecord
  belongs_to :venue

  validates :day_of_week, inclusion: { in: %w(monday tuesday wednesday thursday friday saturday sunday) }
end
