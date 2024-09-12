class Event < ApplicationRecord
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id"
  belongs_to :group, optional: true
  belongs_to :track, optional: true
  belongs_to :venue, optional: true
  belongs_to :badge_class, optional: true
  belongs_to :recurring, optional: true
  has_many :participants, dependent: :delete_all
  has_many :tickets, dependent: :delete_all
  has_many :ticket_items, dependent: :delete_all
  has_many :event_roles, dependent: :delete_all
  has_many :promo_codes, dependent: :delete_all

  validates :end_time, comparison: { greater_than: :start_time }
  validates :status, inclusion: { in: %w(draft pending published closed cancelled) }
  validates :display, inclusion: { in: %w(normal hidden pinned) }
  validates :event_type, inclusion: { in: %w(event group_ticket) }

  accepts_nested_attributes_for :tickets, allow_destroy: true
  accepts_nested_attributes_for :event_roles, allow_destroy: true
  accepts_nested_attributes_for :promo_codes, allow_destroy: true

  ### methods

  def check_group_event_permission(profile)
    event = self
    group = event.group
    tz = group.timezone

    if !group.group_ticket_event_id
      return render json: { result: "ok", check: true, message: "action allowed" }
    end

    if event.owner_id == profile.id || group.is_manager(profile.id) ||
        EventRole.find_by(event_id: event.id, profile_id: profile.id) ||
        EventRole.find_by(event_id: event.id, email: profile.email)

      return true
    end

    ok = TicketItem.where(ticket_type: "group", group_id: group.id, profile_id: profile.id).any? { |ticket_item| ticket_item.check_permission(event) }
  end

  def to_cal
    $SENDER_EMAIL = "send@app.sola.day"
    $SOLA_HOST = "https://app.sola.day"
    timezone = self.timezone

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(self.start_time.in_time_zone(timezone))
      e.dtend       = Icalendar::Values::DateTime.new(self.end_time.in_time_zone(timezone))
      e.summary     = self.title || ""
      e.description = self.content || ""
      e.uid         = "sola-#{self.id}"
      e.status      = "CONFIRMED"
      # e.organizer   = Icalendar::Values::CalAddress.new("mailto:#{$SENDER_EMAIL}", cn: "sola")
      # e.attendee    = ["mailto:#{params[:recipient]}"]
      e.url         = self.event_url
      e.location    = self.event_url
    end

    ics = cal.to_ical
  end

  def timeinfo
    timezone = self.timezone
    start_time = self.start_time.in_time_zone(timezone).strftime('%b %d %H:%M %p')
    end_time = self.end_time.in_time_zone(timezone).strftime('%b %d %H:%M %p')
    "#{start_time} to #{end_time} #{self.start_time.in_time_zone(timezone).zone}"
  end

  def event_url
    "https://app.sola.day/event/detail/#{self.id}"
  end

  def group_url
    "https://app.sola.day/group/#{self.group.try(:handle)}"
  end

  def location_url
    self.geo_lat.present? ? "https://www.google.com/maps/search/?api=1&query=#{self.geo_lat}%2C#{self.geo_lng}" : ""
  end

end
