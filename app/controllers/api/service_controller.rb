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
    # todo : calculate filename from filehash
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

    mailer = SigninMailer.with(code: code, recipient: params[:email]).signin_email
    mailer.deliver_now!

    render json: { result: "ok", email: params[:email] }
  end

  def stats
      group = Group.find(params[:group_id])
      group_id = group.id
      days = params[:days].to_i

      total_events = Event.where(group_id: group_id, status: "open").where("start_time >= ?", DateTime.now - days.day).count
      total_event_hosts = Event.where(group_id: group_id, status: "open").where("start_time >= ?", DateTime.now - days.day).pluck(:owner_id).uniq.count
      total_participants = Participant.where(event: Event.where(group_id: group_id, status: "open").where("start_time >= ?", DateTime.now - days.day)).count
      total_issued_badges = Participant.where(event: Event.where(group_id: group_id, status: "open").where("start_time >= ?", DateTime.now - days.day)).pluck(:badge_id).select { |x| x }.count

      render json: {
        total_events: total_events,
        total_event_hosts: total_event_hosts,
        total_participants: total_participants,
        total_issued_badges: total_issued_badges
      }
    end
end
