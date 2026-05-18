json.marker do
  json.partial! 'api/marker/marker_full', marker: @marker
  json.partial! 'api/group/group_or_nil', group: @marker.group
  if @marker.owner
    json.owner do
      json.extract! @marker.owner, :id, :handle, :nickname, :image_url
    end
  else
    json.owner nil
  end
  if @marker.badge_class
    json.badge_class do
      json.extract! @marker.badge_class, :id, :title, :image_url, :metadata, :content
    end
  else
    json.badge_class nil
  end
end
