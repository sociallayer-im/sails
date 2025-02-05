if venue.present?
  json.venue do
    json.extract! venue, :id, :title, :about, :location, :location_viewport, :location_data, :formatted_address, :link, :capacity, :geo_lat, :geo_lng, :tags
  end
else
  json.venue nil
end
