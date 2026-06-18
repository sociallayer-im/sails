json.extract! event, :id, :title, :event_type, :track_id, :start_time, :end_time, :timezone, :status, :display, :pinned, :theme, :meeting_url, :cover_url, :require_approval, :tags, :max_participant, :min_participant, :participants_count, :badge_class_id, :external_url, :recurring_id, :content, :notes, :requirement_tags, :kind, :venue_id, :form_id, :place_id

place = event.place
if place
  json.location          place.name
  json.formatted_address place.address
  json.geo_lat           place.geo_lat
  json.geo_lng           place.geo_lng
  json.location_viewport place.location_viewport
  json.location_data     nil
  json.place do
    json.partial! "api/place/place", place: place
  end
else
  json.location          nil
  json.formatted_address nil
  json.geo_lat           nil
  json.geo_lng           nil
  json.location_viewport nil
  json.location_data     nil
  json.place             nil
end