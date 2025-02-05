json.partial! 'api/event/event', event: @event
json.partial! 'api/profile/profile_or_nil', profile: @event.owner
json.partial! 'api/venue/venue_or_nil', venue: @event.venue
json.partial! 'api/group/group_or_nil', group: @event.group

json.tickets @event.tickets do |ticket|
  json.extract! ticket, :id, :title, :content, :ticket_type, :quantity, :end_time, :need_approval, :status, :zupass_event_id, :zupass_product_id, :zupass_product_name, :start_date, :end_date, :days_allowed, :tracks_allowed
end

json.event_roles @event.event_roles do |event_role|
  json.extract! event_role, :id, :role, :item_id, :item_type, :nickname, :image_url
end

json.partial! 'api/event/custom_form', custom_form: @event.custom_form
