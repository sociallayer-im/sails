class Event < ApplicationRecord
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id"
  belongs_to :group, optional: true
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
  validates :event_type, inclusion: { in: %w(event) }

  accepts_nested_attributes_for :tickets, allow_destroy: true
  accepts_nested_attributes_for :event_roles, allow_destroy: true
  accepts_nested_attributes_for :promo_codes, allow_destroy: true

  ### methods

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
      e.url         = "#{$SOLA_HOST}/event/detail/#{self.id}"
      e.location    = "#{$SOLA_HOST}/event/detail/#{self.id}"
    end

    ics = cal.to_ical
  end

  ### legacy

  def timeinfo
    timezone = self.timezone
    start_time = self.start_time.in_time_zone(timezone).strftime('%b %d %H:%M %p')
    end_time = self.end_time.in_time_zone(timezone).strftime('%b %d %H:%M %p')
    "#{start_time} to #{end_time} #{self.start_time.in_time_zone(timezone).zone}"
  end

  def send_mail_new_event(recipient)
    if self.geo_lat.present?
      location_url = "https://www.google.com/maps/search/?api=1&query=#{self.geo_lat}%2C#{self.geo_lng}"
    else
      location_url = ""
    end

    mailer = EventMailer.with(
      event_id: self.id,
      recipient: recipient,
      group_url: "https://app.sola.day/group/#{self.group.username}",
      group_name: self.group.username,
      title: self.title,
      timeinfo: self.timeinfo,
      location_url: location_url,
      location: self.location,
      url: "https://app.sola.day/event/detail/#{self.id}",
      ).new_event
    mailer.deliver_now!
  end

  def send_mail_event_invite(recipient)
    if self.geo_lat.present?
      location_url = "https://www.google.com/maps/search/?api=1&query=#{self.geo_lat}%2C#{self.geo_lng}"
    else
      location_url = ""
    end

    mailer = EventMailer.with(
      event_id: self.id,
      recipient: recipient,
      group_url: "https://app.sola.day/group/#{self.group.username}",
      group_name: self.group.username,
      title: self.title,
      timeinfo: self.timeinfo,
      location_url: location_url,
      location: self.location,
      url: "https://app.sola.day/event/detail/#{self.id}",
      ).event_invite
    mailer.deliver_now!
  end

  def send_mail_update_event(recipient)
    if self.geo_lat.present?
      location_url = "https://www.google.com/maps/search/?api=1&query=#{self.geo_lat}%2C#{self.geo_lng}"
    else
      location_url = ""
    end

    event_title = self.title
    email_title = "Your event has been updated"

    mailer = EventMailer.with(
      subject: "Social Layer Event Updated",
      event_id: self.id,
      recipient: recipient,
      group_url: "https://app.sola.day/group/#{self.group.username}",
      group_name: self.group.username,
      event_title: event_title,
      email_title: email_title,
      timeinfo: self.timeinfo,
      location_url: location_url,
      location: self.location,
      url: "https://app.sola.day/event/detail/#{self.id}",
      ).update_event
    mailer.deliver_now!
  end

  def send_mail_cancel_event(recipient)
    if self.geo_lat.present?
      location_url = "https://www.google.com/maps/search/?api=1&query=#{self.geo_lat}%2C#{self.geo_lng}"
    else
      location_url = ""
    end

    event_title = self.title
    email_title = "Your event has been cancelled"

    mailer = EventMailer.with(
      subject: "Social Layer Event Updated",
      event_id: self.id,
      recipient: recipient,
      group_url: "https://app.sola.day/group/#{self.group.username}",
      group_name: self.group.username,
      event_title: event_title,
      email_title: email_title,
      timeinfo: self.timeinfo,
      location_url: location_url,
      location: self.location,
      url: "https://app.sola.day/event/detail/#{self.id}",
      ).update_event
    mailer.deliver_now!
  end
end
