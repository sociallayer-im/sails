json.markers @markers do |marker|
    json.partial! 'api/marker/marker_full', marker: marker
    json.partial! 'api/group/group_or_nil', group: marker.group
end
