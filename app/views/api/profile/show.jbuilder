json.profile do
  json.extract! @profile, :id, :handle, :nickname, :phone, :sol_address, :far_fid, :far_address, :zupass, :image_url, :social_links, :created_at, :updated_at
end
