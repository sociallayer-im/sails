
json.featured_popups @featured_popups do |group|
  json.id group.id
  json.title group.nickname
  json.location group.location
  json.start_date group.start_date
  json.end_date group.end_date
  json.group_tags group.group_tags
  json.website group.website
  json.image_url group.featured_image_url || group.image_url
  json.group do
    json.id group.id
    json.handle group.handle
    json.nickname group.nickname
    json.image_url group.image_url
  end
end

json.popups @popups do |group|
  json.id group.id
  json.title group.nickname
  json.location group.location
  json.start_date group.start_date
  json.end_date group.end_date
  json.group_tags group.group_tags
  json.website group.website
  json.image_url group.featured_image_url || group.image_url
  json.group do
    json.id group.id
    json.handle group.handle
    json.nickname group.nickname
    json.image_url group.image_url
  end
end

json.groups @groups do |group|
  json.extract! group, :id, :handle, :nickname, :image_url, :location, :timezone, :start_date, :end_date, :group_tags, :memberships_count, :events_count
  owner = group.owner
  json.owner do
    json.id owner.id
    json.handle owner.handle
    json.nickname owner.nickname
    json.image_url owner.image_url
  end
end

json.events @events do |event|
  json.extract! event, :id, :title, :event_type, :track_id, :start_time, :end_time, :timezone, :meeting_url, :location, :formatted_address, :cover_url, :tags, :external_url

  if event.owner
    json.owner do
      json.extract! event.owner, :id, :handle, :username, :nickname, :image_url
    end
  else
    json.owner nil
  end

  json.event_roles event.event_roles do |event_role|
    json.extract! event_role, :id, :role, :item_id, :item_type, :nickname, :image_url
  end
end
