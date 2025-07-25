class Event < ApplicationRecord
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id"
  belongs_to :group, optional: true
  belongs_to :track, optional: true
  belongs_to :venue, optional: true
  belongs_to :badge_class, optional: true
  belongs_to :recurring, optional: true
  has_one :custom_form, dependent: :delete, as: :item
  has_many :participants, dependent: :delete_all
  has_many :tickets, dependent: :delete_all
  has_many :ticket_items, dependent: :delete_all
  has_many :event_roles, dependent: :delete_all
  has_many :coupons, dependent: :delete_all
  has_many :stars, -> { where(item_type: "Event", comment_type: "star") }, class_name: "Comment", foreign_key: "item_id"
  has_many :operator_notes, dependent: :delete_all

  validates :end_time, comparison: { greater_than: :start_time }
  validates :status, inclusion: { in: %w(draft open pending published closed cancelled) }
  validates :display, inclusion: { in: %w(normal hidden private public) }
  validates :event_type, inclusion: { in: %w(event group_ticket) }

  accepts_nested_attributes_for :tickets, allow_destroy: true
  accepts_nested_attributes_for :event_roles, allow_destroy: true
  accepts_nested_attributes_for :coupons, allow_destroy: true
  accepts_nested_attributes_for :operator_notes, allow_destroy: true

  attr_accessor :is_starred
  attr_accessor :is_attending

  ### methods

  def self.update_tags(group, old_tag, new_tag)
    evs=Event.where(group: group).where("events.tags @> ARRAY[?]::varchar[]", [old_tag])
    evs.each do |ev|
      ev.tags = ev.tags - [old_tag] + [new_tag]
      ev.save
    end
  end

  def local_start_time
    self.start_time.in_time_zone(self.timezone).to_s
  end

  def local_end_time
    self.end_time.in_time_zone(self.timezone).to_s
  end

  def self.edge_esmeralda_verification()
    if self.group_id == 3579
      self.edge_esmeralda_api_check(self.owner.email)
    end
  end

  def self.edge_esmeralda_api_check(email)
    begin
      url = "https://api-citizen-portal.simplefi.tech/attendees/search/email?email=#{email}"
      response = RestClient.get(url, {
        "x-api-key": "hP@&Oy&w6X2&AM#R6%"
      })
      data = JSON.parse(response)
      data = data.find { |item| item["products"].find { |item| item["popup_city_id"] == 4 } }
      if data
        return true
      end
    rescue => e
      p e
    end

    false
  end

  def parse_host_info
    return nil if host_info.nil?
    result = {}
    info = JSON.parse(host_info)
    result["group_host"] = []
    if info.is_a? Integer
      result["group_host"] << {
        item_id: info,
        item_type: "Group",
        role: "group_host",
      }
    else
      # "speaker", "co_host", "group_host"
      result["speaker"] = []
      info["speaker"].each { |item|
        obj = Profile.find_by(username: item["username"]) || Group.find_by(username: item["username"]) || Profile.find_by(email: item["email"])
        obj = Profile.find_by(id: item["id"]) if obj.nil? && item["id"] != 0
        item_type = obj ? obj.model_name.name : nil
        result["speaker"] << {
          role: "speaker",
          item_type: item_type,
          item_id: obj.try(:id),
          nickname: obj.try(:nickname) || obj.try(:username) || item["nickname"] || item["username"],
          image_url:  obj.try(:image_url) || item["image_url"],
          email: item["email"]
          }
      }

      result["co_host"] = []
      info["co_host"].each { |item|
        obj = Profile.find_by(username: item["username"]) || Group.find_by(username: item["username"]) || Profile.find_by(email: item["email"])
        obj = Profile.find_by(id: item["id"]) if obj.nil? && item["id"] != 0
        item_type = obj ? obj.model_name.name : nil
        result["co_host"] << {
          role: "co_host",
          item_type: item_type,
          item_id: obj.try(:id),
          nickname: obj.try(:nickname) || obj.try(:username) || item["nickname"] || item["username"],
          image_url:  obj.try(:image_url) || item["image_url"],
          email: item["email"]
          }
      }

      if info["group_host"]
        item = info["group_host"]
        obj = Profile.find_by(username: item["username"]) || Group.find_by(username: item["username"]) || Profile.find_by(email: item["email"])
        obj = Profile.find_by(id: item["id"]) if obj.nil? && item["id"] != 0
        result["group_host"] << {
          role: "group_host",
          # event_id: event.id,
          item_type: "Group",
          item_id: obj.try(:id),
          # item_id: item["id"],
          nickname: obj.try(:nickname) || obj.try(:username) || item["nickname"] || item["username"],
          image_url:  obj.image_url || item["image_url"],
          }
      end

      # info["group_host"].each { |item|

      # }
    end
    result
  end

  def update_host_info
    event = self
    return nil if host_info.nil?
    info = JSON.parse(host_info)
    if info.is_a? Integer
      group = Group.find_by(id: info)
      EventRole.create(
        event_id: event.id,
        item_id: group.id,
        item_type: "Group",
        role: "group_host",
        nickname: group.try(:username) || group.try(:nickname),
        image_url: group.try(:image_url),
      )
    else
      # "speaker", "co_host", "group_host"
      info["speaker"].each { |item|
        obj = Profile.find_by(username: item["username"]) || Group.find_by(username: item["username"]) || Profile.find_by(email: item["email"])
        obj = Profile.find_by(id: item["id"]) if obj.nil? && item["id"] != 0
        item_type = obj ? obj.model_name.name : nil
        EventRole.create(
          event_id: event.id,
          role: "speaker",
          item_type: item_type,
          item_id: obj.try(:id),
          nickname: obj.try(:nickname) || obj.try(:username) || item["nickname"] || item["username"],
          image_url:  obj.try(:image_url) || item["image_url"],
          email: item["email"]
        )
      }

      info["co_host"].each { |item|
        obj = Profile.find_by(username: item["username"]) || Group.find_by(username: item["username"]) || Profile.find_by(email: item["email"])
        obj = Profile.find_by(id: item["id"]) if obj.nil? && item["id"] != 0
        item_type = obj ? obj.model_name.name : nil
        EventRole.create(
          event_id: event.id,
          role: "co_host",
          item_type: item_type,
          item_id: obj.try(:id),
          nickname: obj.try(:nickname) || obj.try(:username) || item["nickname"] || item["username"],
          image_url:  obj.try(:image_url) || item["image_url"],
          email: item["email"]
        )
      }

      if info["group_host"]
        item = info["group_host"]
        obj = Profile.find_by(username: item["username"]) || Group.find_by(username: item["username"]) || Profile.find_by(email: item["email"])
        obj = Profile.find_by(id: item["id"]) if obj.nil? && item["id"] != 0
        EventRole.create(
          event_id: event.id,
          role: "group_host",
          item_type: "Group",
          item_id: obj.try(:id),
          nickname: obj.try(:nickname) || obj.try(:username) || item["nickname"] || item["username"],
          image_url:  obj.image_url || item["image_url"],
        )
      end
    end
  end

  def check_group_event_permission(profile)
    event = self
    group = event.group
    tz = group.timezone

    if !group.group_ticket_event_id
      return render json: { result: "ok", check: true, message: "action allowed" }
    end

    if event.owner_id == profile.id || group.is_manager(profile.id) ||
        EventRole.find_by(event_id: event.id, item_type: "Profile", item_id: profile.id) ||
        EventRole.find_by(event_id: event.id, email: profile.email)

      return true
    end

    ok = TicketItem.where(ticket_type: "group", group_id: group.id, profile_id: profile.id).any? { |ticket_item| ticket_item.check_permission(event) }
  end

  def dump_json
    {
      id: self.id.to_s,
      owner_id: self.owner_id,
      owner_name: self.owner.handle,
      owner_nickname: self.owner.nickname,
      group_id: self.group_id,
      group_name: self.group.try(:handle),
      group_nickname: self.group.try(:nickname),
      title: self.title,
      start_time: self.start_time,
      end_time: self.end_time,
      timezone: self.timezone,
      event_url: self.event_url,
      group_url: self.group_url,
      meeting_url: self.meeting_url,
      external_url: self.external_url,
      location: self.location,
      formatted_address: self.formatted_address,
      location_viewport: self.location_viewport,
      geo_lat: self.geo_lat,
      geo_lng: self.geo_lng,
      cover_url: self.cover_url,
      require_approval: self.require_approval,
      content: self.content,
      tags: self.tags,
      max_participant: self.max_participant,
      participants_count: self.participants_count,
      event_type: self.event_type,
      status: self.status,
      display: self.display,
      venue_id: self.venue_id,
      created_at: self.created_at,
      updated_at: self.updated_at,

      # track_id: self.track_id,
      # recurring_id: self.recurring_id,
      event_roles: self.event_roles.map {|x| x.nickname || x.profile.try(:handle) },
      # event_roles: self.event_roles.map do |x|
      #   {
      #     nickname: x.nickname || x.profile.try(:handle),
      #     image_url: x.image_url,
      #     role: x.role,
      #     about: x.about,
      #   }
      # end
    }
  end

  def create_event_webhook
    begin
      if group_id
        webhook = Config.find_by(name: "event_webhook_url", group_id: group_id).try(:value)
        if webhook
          payload = self.dump_json
          payload[:resource] = "event"
          payload[:action] ="create"
          RestClient.post(webhook, payload)
        end
      end
    rescue => e
      Rails.logger.error("Error creating event webhook: #{e.message}")
    end
  end

  def to_cal
    $SENDER_EMAIL = "send@app.sola.day"
    $SOLA_HOST = "https://app.sola.day"
    timezone = self.timezone

    cal = Icalendar::Calendar.new
    cal.ip_method      = "REQUEST"
    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(self.start_time.in_time_zone(timezone))
      e.dtend       = Icalendar::Values::DateTime.new(self.end_time.in_time_zone(timezone))
      e.summary     = self.title || ""
      e.description = self.content || ""
      e.uid         = "sola-#{self.id}"
      e.status      = "CONFIRMED"
      e.organizer   = Icalendar::Values::CalAddress.new( cn: "sola")
      # e.attendee    = Icalendar::Values::CalAddress.new("mailto:a@example.com", cn: "a@example.com")
      e.url         = self.event_url
      e.location    = self.event_url
    end

    ics = cal.to_ical
  end

  def to_cal_for(email)
    $SENDER_EMAIL = "send@app.sola.day"
    $SOLA_HOST = "https://app.sola.day"
    timezone = self.timezone

    location = self.venue.present? ? self.venue.title : self.location

    cal = Icalendar::Calendar.new
    cal.ip_method      = "REQUEST"
    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(self.start_time.in_time_zone(timezone))
      e.dtend       = Icalendar::Values::DateTime.new(self.end_time.in_time_zone(timezone))
      e.summary     = self.title || ""
      e.description = self.content || ""
      e.uid         = "sola-#{self.id}"
      e.status      = "CONFIRMED"
      e.organizer   = Icalendar::Values::CalAddress.new("mailto:event@sola.day", cn: "sola")
      e.attendee    = Icalendar::Values::CalAddress.new("mailto:#{email}", cn: email)
      e.url         = self.event_url
      e.location    = location
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
