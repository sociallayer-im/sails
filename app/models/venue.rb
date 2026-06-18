class Venue < ApplicationRecord
  TSID_GENERATOR = Tsid::Generator.new

  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id", optional: true
  belongs_to :group
  belongs_to :place, optional: true
  has_many :events
  has_many :venue_timeslots
  has_many :venue_overrides
  has_many :availabilities, as: :item

  before_create :assign_key

  validates :end_date, comparison: { greater_than: :start_date }, if: -> { start_date.present? && end_date.present? }

  accepts_nested_attributes_for :venue_timeslots, allow_destroy: true
  accepts_nested_attributes_for :venue_overrides, allow_destroy: true
  accepts_nested_attributes_for :availabilities, allow_destroy: true

  validates :visibility, inclusion: { in: %w(all member manager none) }, allow_nil: true

  private

  def assign_key
    self.key ||= TSID_GENERATOR.generate
  end

  public

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
    overlap_scope = Event.where(venue_id: self.id)
                         .where("start_time < ? AND end_time > ?", event_end, event_start)
                         .where.not(status: "cancelled")
    overlap_scope = overlap_scope.where.not(id: event_id) if event_id
    if overlap_scope.any?
      return false, "Event is on a day the venue is already booked"
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
    else
      # Venue has weekly slots configured — an unlisted day means closed
      has_weekly_slots = Availability.where(item_id: self.id, item_type: "Venue").where.not(day_of_week: nil).exists?
      if has_weekly_slots
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