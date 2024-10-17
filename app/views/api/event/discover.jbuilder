
json.featured_popups @featured_popups do |popup|
  json.extract! popup, :id, :title, :location, :start_date, :end_date, :group_tags, :website, :image_url
end

json.cnx_popups @cnx_popups do |popup|
  json.extract! popup, :id, :title, :location, :start_date, :end_date, :group_tags, :website, :image_url
end

json.popups @popups do |popup|
  json.extract! popup, :id, :title, :location, :start_date, :end_date, :group_tags, :website, :image_url
end

json.groups @groups do |group|
  json.extract! group, :id, :handle, :nickname, :location, :timezone, :start_date, :end_date, :group_tags
end

json.events @events do |event|
    json.extract! event, :id, :title, :event_type, :track_id, :start_time, :end_time, :timezone, :meeting_url, :location, :formatted_address, :cover_url, :tags, :external_url
end
