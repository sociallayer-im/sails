class Venue < ApplicationRecord
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id", optional: true
  belongs_to :group
  has_many :events
  has_many :venue_timeslots
  has_many :venue_overrides
  has_many :availabilities, as: :item

  validates :end_date, comparison: { greater_than: :start_date }, allow_nil: true

  accepts_nested_attributes_for :venue_timeslots, allow_destroy: true
  accepts_nested_attributes_for :venue_overrides, allow_destroy: true
  accepts_nested_attributes_for :availabilities, allow_destroy: true

  validates :visibility, inclusion: { in: %w(all member manager none) }, allow_nil: true

  def check_availability_old(event_start, event_end, timezone, event_id = nil)
    start_time = event_start.in_time_zone(timezone)
    end_time = event_end.in_time_zone(timezone)
    start_date = start_time.to_date
    end_date = end_time.to_date
    if self.start_date
      if start_date < self.start_date
        return false, "Event is before venue availibility begins"
      end
    end
    if self.end_date
      if end_date > self.end_date
        return false, "Event is after venue availibility ends"
      end
    end
    if event_id
      if Event.where(venue_id: self.id).where("start_time < ? AND end_time > ?", event_end, event_start).where.not(id: event_id).any?
        return false, "Event is on a day the venue is already booked"
      end
    else
      if Event.where(venue_id: self.id).where("start_time < ? AND end_time > ?", event_end, event_start).any?
        return false, "Event is on a day the venue is already booked"
      end
    end
    override = VenueOverride.find_by(venue_id: self.id, day: start_date)
    timeslot = VenueTimeslot.find_by(venue_id: self.id, day_of_week: start_time.strftime("%A").downcase)
    if override
      any_override_time = override.data.any? do |start_at, end_at|
        TimeOfDay.parse(start_at).total_minutes <= (start_time.seconds_since_midnight / 60) &&
        TimeOfDay.parse(end_at).total_minutes >= (end_time.seconds_since_midnight / 60)
      end
      if !any_override_time
        return false, "Event is on a day when the venue is not available"
      end
      return true, "Event is within venue hours"
    elsif timeslot
      any_timeslot_time = timeslot.data.any? do |start_at, end_at|
        TimeOfDay.parse(start_at).total_minutes <= (start_time.seconds_since_midnight / 60) &&
        TimeOfDay.parse(end_at).total_minutes >= (end_time.seconds_since_midnight / 60)
      end
      if !any_timeslot_time
        return false, "Event is on a day when the venue is not available"
      end
      return true, "Event is within venue hours"
    else
      return true, "Event is within venue hours"
    end
  end


  def check_availability(event_start, event_end, timezone, event_id = nil)
    start_time = event_start.in_time_zone(timezone)
    end_time = event_end.in_time_zone(timezone)
    start_date = start_time.to_date
    end_date = end_time.to_date
    
    if self.start_date
      if start_date < self.start_date
        return false, "Event is before venue availibility begins"
      end
    end
    if self.end_date
      if end_date > self.end_date
        return false, "Event is after venue availibility ends"
      end
    end
    if event_id
      if Event.where(venue_id: self.id).where("start_time < ? AND end_time > ?", event_end, event_start).where.not(id: event_id).any?
        return false, "Event is on a day the venue is already booked"
      end
    else
      if Event.where(venue_id: self.id).where("start_time < ? AND end_time > ?", event_end, event_start).any?
        return false, "Event is on a day the venue is already booked"
      end
    end
    override = Availability.find_by(item_id: self.id, item_type: "Venue", day: start_date)
    timeslot = Availability.find_by(item_id: self.id, item_type: "Venue", day_of_week: start_time.strftime("%A").downcase)
    if override
      any_override_time = override.intervals.any? do |start_at, end_at|
        TimeOfDay.parse(start_at).total_seconds <= start_time.seconds_since_midnight &&
        TimeOfDay.parse(end_at).total_seconds >= end_time.seconds_since_midnight
      end
      if !any_override_time
        return false, "Event is on a day when the venue is not available"
      end
    elsif timeslot
      any_timeslot_time = timeslot.intervals.any? do |start_at, end_at|
        TimeOfDay.parse(start_at).total_seconds <= start_time.seconds_since_midnight &&
        TimeOfDay.parse(end_at).total_seconds >= end_time.seconds_since_midnight
      end
      if !any_timeslot_time
        return false, "Event is on a day when the venue is not available"
      end
    end
    return true, "Event is within venue hours"
  end

end

class TimeOfDay
  include Comparable

  attr_reader :hours, :minutes

  def initialize(hours, minutes)
    @hours = hours
    @minutes = minutes
  end

  # parse "HH:MM" string
  def self.parse(time_str)
    hours, minutes = time_str.split(":").map(&:to_i)
    new(hours, minutes)
  end

  def total_minutes
    @hours * 60 + @minutes
  end

  def total_seconds
    @hours * 3600 + @minutes * 60
  end

  def <=>(other)
    total_minutes <=> other.total_minutes
  end

  def to_s
    format("%02d:%02d", @hours, @minutes)
  end
end