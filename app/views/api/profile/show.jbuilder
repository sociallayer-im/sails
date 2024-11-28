
if @profile
  json.profile do
    json.extract! @profile, :id, :handle, :nickname, :phone, :sol_address, :far_fid, :far_address, :zupass, :image_url, :about, :location, :social_links, :created_at, :updated_at
  end
else
  json.profile nil
end
