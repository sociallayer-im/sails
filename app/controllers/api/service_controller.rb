require "aws-sdk-s3"
require "digest"

$client = Aws::S3::Client.new(
  access_key_id: "#{ENV['AWS_ACCESS_KEY_ID']}",
  secret_access_key: "#{ENV['AWS_SECRET_ACCESS_KEY']}",
  endpoint: "https://#{ENV['AWS_HOST']}",
  region: "auto",
)

class Api::ServiceController < ApiController
  def upload_image
    profile = current_profile!

    sha = Digest::SHA2.new
    File.open(params[:data]) do |f|
      while chunk = f.read(256)
        sha << chunk
      end
    end

    # todo : log handle
    # key = SecureRandom.hex(10)

    key = sha.hexdigest.slice(0...16)
    resp = $client.put_object({
      body: params[:data],
      bucket: "sola",
      key: key
    })
    render json: { result: resp.as_json, key: key, url: "#{ENV['S3_URL']}#{key}" }
  end

  def send_email
    code = rand(10_000..100_000)
    token = ProfileToken.create(context: params[:context], sent_to: params[:email], code: code)

    mailer = SigninMailer.with(code: code, recipient: params[:email]).signin
    mailer.deliver_now!

    render json: { result: "ok", email: params[:email] }
  end

  def stats
      group = Group.find(params[:group_id])
      group_id = group.id
      group_events = Event.where(group_id: group_id, status: ["published", "closed"])

      days = params[:days].to_i
      if days > 0
        group_events = group_events.where("start_time >= ?", DateTime.now - days.day)
      end

      total_events = group_events.count
      total_event_hosts = group_events.pluck(:owner_id).uniq.count
      total_participants = Participant.where(event: group_events).count
      # todo : add checked event participants
      # todo : add event co-hosts

      render json: {
        total_events: total_events,
        total_event_hosts: total_event_hosts,
        total_participants: total_participants,
      }
  end

  def icalendar_for_group
    group = Group.find(params[:group_id])
    cal = Icalendar::Calendar.new
    Event.where(group_id: group.id, status: ['published']).where('start_time > ?', DateTime.now - 7.days).each do |ev|
        cal.event do |e|
          e.dtstart     = Icalendar::Values::DateTime.new(ev.start_time.in_time_zone("Etc/UTC"))
          e.dtend       = Icalendar::Values::DateTime.new(ev.end_time.in_time_zone("Etc/UTC"))
          e.summary     = ev.title || ""
          e.uid         = "sola-#{ev.id}"
          e.status      = "CONFIRMED"
          e.organizer   = Icalendar::Values::CalAddress.new("mailto:send@app.sola.day", cn: group.username)
          e.url         = "https://app.sola.day/event/detail/#{ev.id}"
          e.location    = "https://app.sola.day/event/detail/#{ev.id}"
        end
    end
    ics = cal.to_ical

    render plain: ics
  end

  def get_participanted_events_by_email
    profile = Profile.find_by(email: params[:email])
    events = Event.joins(:participants).where(participants: { profile_id: profile.id })
    if params[:group_id]
      group = Group.find_by(id: params[:group_id])
      events = events.where(group: group)
    end
    if params[:collection] == "past"
      events = events.where("end_time < ?", DateTime.now)
    elsif params[:collection] == "upcoming"
      events = events.where("end_time >= ?", DateTime.now)
    end
    events = events.order(start_time: :desc).all
    render json: { events: events.as_json(only: [:id, :title, :start_time, :end_time, :location, :status]) }
  end

  def get_hosted_events_by_email
    profile = Profile.find_by(email: params[:email])
    events = Event.where(owner_id: profile.id, status: ["published", "open"])
    if params[:group_id]
      group = Group.find_by(id: params[:group_id])
      events = events.where(group: group)
    end
    if params[:collection] == "past"
      events = events.where("end_time < ?", DateTime.now)
    elsif params[:collection] == "upcoming"
      events = events.where("end_time >= ?", DateTime.now)
    end
    events = events.order(start_time: :desc).all
    render json: { events: events.as_json(only: [:id, :title, :start_time, :end_time, :location, :status]) }
  end

  def get_user_groups_by_email
    profile = Profile.find_by(email: params[:email])
    groups = Group.where(members: profile)
    render json: { groups: groups.as_json }
  end

  def get_user_tickets_by_email
    profile = Profile.find_by(email: params[:email])
    tickets = Ticket.where(profile: profile)
    render json: { tickets: tickets.as_json }
  end

  def get_user_related_groups
    # PopupCity.includes(:group).where("popup_cities.group_tags @> ARRAY[?]::varchar[]", [":cnx"]).order(start_date: :desc).pluck(:group_id)
    group_ids = [3431, 3519, 3527, 3502, 3477, 3507, 3504, 1572, 3463, 3492, 3491, 3495, 3486, 3456]
    profile_ids = params[:profile_id]
    group_data = Profile.organize_profile_groups(profile_ids)


    render json: { group_data: group_data }
  end
end
