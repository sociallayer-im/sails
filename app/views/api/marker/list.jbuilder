json.markers @markers do |marker|
    json.extract! marker, :id, :title, :pin_image_url, :cover_image_url, :category, :marker_type, :about, :link,
                          :start_time, :end_time, :location, :formatted_address, :location_viewport, :location_data, :geo_lat, :geo_lng,
                          :highlight, :message, :map_checkins_count, :created_at, :updated_at
    json.group do
      json.extract! marker.group, :id, :handle, :nickname, :image_url
    end
end
