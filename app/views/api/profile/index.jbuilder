json.array! @profiles do |profile|
  json.extract! profile, :id, :handle, :nickname, :phone, :sol_address, :far_fid, :far_address, :fuel_address, :mina_address, :zupass, :image_url, :social_links, :created_at, :updated_at
end
