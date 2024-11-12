json.extract! @event, :id, :title, :event_type, :start_time, :end_time, :timezone, :status, :display, :pinned, :theme, :meeting_url, :location, :location_data, :formatted_address, :geo_lat, :geo_lng, :cover_url, :require_approval, :content, :tags, :max_participant, :min_participant, :participants_count, :badge_class_id, :external_url, :notes, :recurring_id

# json.host_info (@event.host_info.present? ? JSON.parse(@event.host_info) : nil)
json.host_info @event.parse_host_info

if @event.venue
  json.venue do
    json.extract! @event.venue, :id, :title, :about, :location, :location_viewport, :formatted_address, :link, :capacity, :geo_lat, :geo_lng, :tags
  end
else
  json.venue nil
end

if @event.owner
  json.owner do
    json.extract! @event.owner, :id, :handle, :username, :nickname, :image_url
  end
else
  json.owner nil
end

if @event.group
  json.group do
    json.extract! @event.group, :id, :handle, :username, :nickname, :image_url, :timezone
  end
else
  json.group nil
end

json.tickets @event.tickets do |ticket|
  json.extract! ticket, :id, :title, :content, :ticket_type, :quantity, :end_time, :need_approval, :status, :zupass_event_id, :zupass_product_id, :zupass_product_name, :start_date, :end_date, :days_allowed, :tracks_allowed
end

json.event_roles @event.event_roles do |event_role|
  json.extract! event_role, :id, :role, :item_id, :item_type, :nickname, :image_url
end

if @event.custom_form
  json.custom_form do
    json.extract! @event.custom_form, :id, :title, :description, :status
    json.form_fields @event.custom_form.form_fields do |form_field|
      json.extract! form_field, :id, :label, :description, :field_type, :field_options, :required, :position
    end
  end
else
  json.custom_form nil
end