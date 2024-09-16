class Venue < ApplicationRecord
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id", optional: true
  belongs_to :group
  has_many :events
  has_many :venue_timeslots
  has_many :venue_overrides

  validates :end_date, comparison: { greater_than: :start_date }, allow_nil: true

  accepts_nested_attributes_for :venue_timeslots, allow_destroy: true
  accepts_nested_attributes_for :venue_overrides, allow_destroy: true

  validates :visibility, inclusion: { in: %w(all manager none) }

  def check_availability(event, timezone)
    if self.start_date
      if event.start_time.in_time_zone(timezone).to_date < self.start_date
        return false, "Event is before venue is open"
      end
    end
    if self.end_date
      if event.end_time.in_time_zone(timezone).to_date > self.end_date
        return false, "Event is after venue is closed"
      end
    end
    if self.venue_timeslots.any?
      if !self.venue_timeslots.any? { |timeslot| timeslot.day_of_week == event.start_time.in_time_zone(timezone).strftime("%A") }
        return false, "Event is not within venue hours"
      end
    end
    return true, "Event is within venue hours"
  end
end
