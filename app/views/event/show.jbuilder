json.extract! @event, :id, :title, :event_type, :start_time, :end_time, :timezone, :meeting_url, :location, :formatted_address, :geo_lat, :geo_lng, :cover_url, :require_approval, :content, :tags, :max_participant, :min_participant, :participants_count, :badge_class_id, :external_url, :notes

json.venue do
  json.extract! @event.venue, :id, :name, :address, :city, :state, :country, :zip_code, :latitude, :longitude
end

json.group do
  json.extract! @event.group, :id, :handle, :nickname, :timezone, :can_publish_event, :can_join_event, :can_view_event
end

json.tickets @event.tickets do |ticket|
  json.extract! ticket, :id, :title, :content, :ticket_type, :quantity, :end_time, :need_approval, :status, :zupass_event_id, :zupass_product_id, :zupass_product_name, :start_date, :end_date, :days_allowed, :tracks_allowed
end

json.event_roles @event.event_roles do |event_role|
  json.extract! event_role, :id, :role, :group_id, :profile_id, :email, :nickname, :image_url
end
