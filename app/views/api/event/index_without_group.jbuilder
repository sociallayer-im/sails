json.events @events do |event|

json.partial! 'api/event/event', event: event
json.star @with_stars ? @stars.find {|x| x == event.id }.present? : nil
json.partial! 'api/profile/profile', profile: event.owner
json.partial! 'api/venue/venue', venue: event.venue
json.partial! 'api/group/group', group: event.group

# json.tickets event.tickets do |ticket|
#   json.extract! ticket, :id, :title, :content, :ticket_type, :quantity, :end_time, :need_approval, :status, :zupass_event_id, :zupass_product_id, :zupass_product_name, :start_date, :end_date, :days_allowed, :tracks_allowed
# end

# json.event_roles event.event_roles do |event_role|
#     json.extract! event_role, :id, :role, :group_id, :profile_id, :nickname, :image_url
# end
end
