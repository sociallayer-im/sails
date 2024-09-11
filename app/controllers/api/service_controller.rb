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

    # todo : log username
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

    # mailer = SigninMailer.with(code: code, recipient: params[:email]).signin_email
    # mailer.deliver_now!

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
end
