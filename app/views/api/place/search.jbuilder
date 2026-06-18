json.places @places do |place|
  json.partial! "place", place: place
end
