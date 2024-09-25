json.profile do
  json.extract! @profile, :id, :handle, :nickname, :phone, :sol_address, :farcaster_fid, :farcaster_address, :zupass, :image_url, :social_links, :created_at, :updated_at
end