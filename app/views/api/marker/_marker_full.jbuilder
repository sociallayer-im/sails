json.extract! marker, :id, :title, :pin_image_url, :cover_image_url, :category, :marker_type, :about, :link,
:start_time, :end_time, :highlight, :message, :map_checkins_count, :created_at, :updated_at, :place_id

place = marker.place
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