json.badge do
  json.extract! @badge, :id, :index, :title, :image_url, :metadata, :content, :status, :display, :hashtags, :value, :start_time, :end_time, :chain_index, :chain_space, :chain_txhash, :created_at, :updated_at
  json.creator do
    json.extract! @badge.creator, :id, :handle, :nickname, :image_url
  end
  json.owner do
    json.extract! @badge.owner, :id, :handle, :nickname, :image_url
  end
  if @badge.badge_class
    json.badge_class do
      json.extract! @badge.badge_class, :id, :title, :image_url, :metadata, :content, :transferable, :badge_type, :group_id
    end
  else
    json.badge_class nil
  end
end
