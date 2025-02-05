if profile.present?
  json.profile do
  json.extract! profile, :id, :handle, :username, :nickname, :image_url
  end
else
  json.profile nil
end