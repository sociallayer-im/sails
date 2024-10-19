
json.featured_popups @featured_popups do |popup|
  json.extract! popup, :id, :title, :location, :start_date, :end_date, :group_tags, :website, :image_url
  group = popup.group
  json.group do
    json.id group.id
    json.handle group.handle
    json.nickname group.nickname
    json.image_url group.image_url
  end
end

json.cnx_popups @cnx_popups do |popup|
  json.extract! popup, :id, :title, :location, :start_date, :end_date, :group_tags, :website, :image_url
  group = popup.group
  json.group do
    json.id group.id
    json.handle group.handle
    json.nickname group.nickname
    json.image_url group.image_url
  end
end

json.popups @popups do |popup|
  json.extract! popup, :id, :title, :location, :start_date, :end_date, :group_tags, :website, :image_url
  group = popup.group
  json.group do
    json.id group.id
    json.handle group.handle
    json.nickname group.nickname
    json.image_url group.image_url
  end
end

json.groups @groups do |group|
  json.extract! group, :id, :handle, :nickname, :image_url, :location, :timezone, :start_date, :end_date, :group_tags, :memberships_count, :events_count
  owner = group.get_owner
  json.owner do
    json.id owner.id
    json.handle owner.handle
    json.nickname owner.nickname
    json.image_url owner.image_url
  end
end

json.events @events do |event|
    json.extract! event, :id, :title, :event_type, :track_id, :start_time, :end_time, :timezone, :meeting_url, :location, :formatted_address, :cover_url, :tags, :external_url
end
