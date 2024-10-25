json.events @events do |event|
json.extract! event, :id, :title, :event_type, :track_id, :start_time, :end_time, :timezone, :timezone, :status, :display, :pinned, :theme, :meeting_url, :location, :formatted_address, :geo_lat, :geo_lng, :cover_url, :require_approval, :tags,
                     :max_participant, :min_participant, :participants_count, :badge_class_id, :external_url, :recurring_id, :created_at, :updated_at, :updated_at

# json.host_info (event.host_info.present? ? JSON.parse(event.host_info) : nil)
json.host_info event.parse_host_info


if @with_stars
    json.star @stars.find {|x| x.item_id == event.id }.present?
else
    json.star nil
end

if event.owner
    json.owner do
    json.extract! event.owner, :id, :handle, :username, :nickname, :image_url
    end
else
    json.owner nil
end

if event.venue
    json.venue do
    json.extract! event.venue, :id, :title, :about, :location, :location_viewport, :formatted_address, :link, :capacity, :geo_lat, :geo_lng, :tags
    end
else
    json.venue nil
end

if event.group
    json.group do
    json.extract! event.group, :id, :handle, :username, :nickname, :timezone
    end
else
    json.group nil
end

# json.tickets event.tickets do |ticket|
#   json.extract! ticket, :id, :title, :content, :ticket_type, :quantity, :end_time, :need_approval, :status, :zupass_event_id, :zupass_product_id, :zupass_product_name, :start_date, :end_date, :days_allowed, :tracks_allowed
# end

# json.event_roles event.event_roles do |event_role|
#     json.extract! event_role, :id, :role, :group_id, :profile_id, :nickname, :image_url
# end
end
