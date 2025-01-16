json.group do
  json.extract! @group, :id, :name, :description, :image_url, :created_at, :updated_at
end
